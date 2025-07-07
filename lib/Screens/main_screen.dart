import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // status bar style
import 'dart:async';
import 'notes_screen.dart';
import 'expanses_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects_flutter/services/firestore_services.dart';
import '../theme/app_theme.dart';
import '../widgets/improved_charts.dart' as improved;
import '../widgets/animated_charts.dart' as animated;
import '../data/monthly_report_data.dart';
import '../widgets/finflow_line_chart.dart';
import 'financial_goals_screen.dart';
import 'notifications_page.dart';
import 'settings_page.dart';
import 'charts_screen.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/last_month_category_bar_chart.dart';

class MainScreen extends StatefulWidget {
  final List<String> selectedGoals; // Selected financial goals
  final Map<String, dynamic> surveyResults; // Survey results
  final int themeIndex;
  final Function(int)? onThemeUpdated;

  const MainScreen({
    super.key,
    required this.selectedGoals,
    required this.surveyResults,
    this.themeIndex = 0,
    this.onThemeUpdated,
  });

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ScrollController _scrollController = ScrollController();
  double _bannerOpacity = 1.0;
  double _bannerOffset = 0.0;
  double _bannerFade = 1.0;

  String _firstName = '';
  String _lastName  = '';
  String _username = '';

  /// Live data pulled from Firestore
  List<Map<String, dynamic>> _categories         = [];
  List<Map<String, dynamic>> _recentTransactions = [];

  double _totalBalance  = 0.0;   // from balance/current
  double _monthlyBudgetLeft = 0.0;   // idem
  double _monthlyBudgetTarget = 0.0;   // idem
  double _spent = 0.0;

  StreamSubscription? _catSub;
  StreamSubscription? _balSub;
  StreamSubscription? _trxSub;

  String _selectedFilter = 'All';

  // Theme management
  late int _selectedThemeIndex; // Will be initialized from widget.themeIndex
  bool _goalsBannerVisible = true;

  // Chart management
  improved.ChartType _selectedChartType = improved.ChartType.line;
  bool _isMonthlyChart = false;

  int _daysLeft = 30;
  DateTime? _lastResetDate;

  // Add MonthlyReportData instance
  final MonthlyReportData monthlyReportData = MonthlyReportData();

  @override
  void initState() {
    super.initState();
    _selectedThemeIndex = widget.themeIndex;
    _scrollController.addListener(_onScroll);
    _initDaysLeft();

    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetch user data
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .then((docSnapshot) {
        if (docSnapshot.exists) {
          setState(() {
            _firstName = docSnapshot.get('firstName') ?? '';
            _lastName  = docSnapshot.get('lastName')  ?? '';
            _username  = docSnapshot.get('username')  ?? '';
          });
        }
      }).catchError((_) {});

      // streams
      // 1) categories
      _catSub = FirestoreService.categoryStream().listen((snap) {
        setState(() {
          _categories = [
            ...snap.docs.map((d) {
              final data = d.data();
              return {
                'id'    : d.id,
                'name'  : data['name'] as String? ?? '',
                'icon'  : IconData(data['icon'] as int? ?? 0,
                    fontFamily: 'MaterialIcons'),
                'color' : Color(data['color'] as int? ?? 0xFF000000),
                'budget': (data['budget'] as num?)?.toDouble() ?? 0.0,
              };
            }),
            {   // Add Category
              'name'  : 'Add Category',
              'icon'  : Icons.add,
              'color' : Colors.grey,
              'budget': 0.0,
            }
          ];
        });
      });

      // 2) balance
      _balSub = FirestoreService.balanceStream().listen((doc) {
        final data = doc.data() ?? <String, dynamic>{};
        setState(() {
          _totalBalance  = (data['total'] ?? 0).toDouble();
          _monthlyBudgetLeft = (data['monthlyBudgetLeft'] ?? 0).toDouble();
          _monthlyBudgetTarget = (data['monthlyBudgetTarget'] ?? 0).toDouble();
        });
      });

      // 3) recent transactions (last20)
      _trxSub = FirestoreService.recentTxStream(20).listen((snap) {
        setState(() {
          final seen = <String>{};
          _recentTransactions = snap.docs.map((d) {
            final data = d.data();
            final isNP = data['notPriority'] as bool? ?? false;
            final catName = data['catName'] as String? ?? '';
            final cat = _categories.firstWhere(
              (c) => c['name'] == catName && c['icon'] == (_categories.firstWhere((c2) => c2['name'] == catName, orElse: () => {})['icon']),
              orElse: () => {},
            );
            return {
              'id'           : d.id,
              'category'     : catName.isEmpty ? '' : catName,
              'amount'       : (data['amount'] as num?)?.toDouble() ?? 0.0,
              'icon'         : isNP
                  ? Icons.remove
                  : (cat['icon'] ?? Icons.add),
              'color'        : isNP
                  ? Colors.grey
                  : (cat['color'] ?? Colors.blueGrey),
              'isNotPriority': isNP,
              'productName'  : data['productName'],
            };
          })
          // Deduplicate by transaction ID
          .where((tx) => seen.add(tx['id'] as String))
          .toList();
        });
      });
    }
  }

  void _initDaysLeft() {
    final now = DateTime.now();
    if (_lastResetDate == null) {
      _lastResetDate = DateTime(now.year, now.month, now.day);
      _daysLeft = 30;
    } else {
      final daysPassed = now.difference(_lastResetDate!).inDays;
      _daysLeft = (30 - daysPassed).clamp(0, 30);
    }
  }

  void _resetDaysLeft() {
    setState(() {
      _lastResetDate = DateTime.now();
      _daysLeft = 30;
    });
  }

  @override
  void dispose() {
    _catSub?.cancel();
    _balSub?.cancel();
    _trxSub?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final off = _scrollController.offset;
    setState(() {
      if (off > 100) {
        _bannerOpacity = 0.0;
        _bannerOffset  = 100;
      } else {
        _bannerOpacity = 1.0 - (off / 100);
        _bannerOffset  = off;
      }
    });
  }

  // Get current theme
  ColorScheme get _currentTheme => AppTheme.themes[_selectedThemeIndex];

  // Generate chart data from categories
  List<improved.ChartData> get _chartData {
    final chartColors = AppTheme.getChartColors(_currentTheme);
    return _categories
        .where((cat) => cat['name'] != 'Add Category' && cat['budget'] > 0)
        .map((cat) {
      final index = _categories.indexOf(cat) % chartColors.length;
      return improved.ChartData(
        label: cat['name'],
        value: cat['budget'],
        color: chartColors[index],
        icon: cat['icon'],
      );
    }).toList();
  }

  // Generate sample data for axis chart
  List<improved.ChartData> get _axisChartData {
    if (_isMonthlyChart) {
      return [
        improved.ChartData(label: 'Jan', value: 1200, color: _currentTheme.primary),
        improved.ChartData(label: 'Feb', value: 1800, color: _currentTheme.secondary),
        improved.ChartData(label: 'Mar', value: 1500, color: _currentTheme.tertiary),
        improved.ChartData(label: 'Apr', value: 2200, color: _currentTheme.primary),
        improved.ChartData(label: 'May', value: 1900, color: _currentTheme.secondary),
        improved.ChartData(label: 'Jun', value: 2500, color: _currentTheme.tertiary),
      ];
    } else {
      return [
        improved.ChartData(label: 'Week 1', value: 300, color: _currentTheme.primary),
        improved.ChartData(label: 'Week 2', value: 450, color: _currentTheme.secondary),
        improved.ChartData(label: 'Week 3', value: 380, color: _currentTheme.tertiary),
        improved.ChartData(label: 'Week 4', value: 520, color: _currentTheme.primary),
      ];
    }
  }

  void _showThemeSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose Theme', style: AppTheme.getHeadingStyle(_currentTheme)),
        backgroundColor: _currentTheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(AppTheme.themes.length, (index) {
            final theme = AppTheme.themes[index];
            return ListTile(
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: AppTheme.getPrimaryGradient(theme),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(
                AppTheme.themeNames[index],
                style: TextStyle(
                  color: _currentTheme.onSurface,
                  fontWeight: _selectedThemeIndex == index ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: _selectedThemeIndex == index,
              onTap: () {
                setState(() {
                  _selectedThemeIndex = index;
                });
                widget.onThemeUpdated?.call(index);
                Navigator.pop(context);
              },
            );
          }),
        ),
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notifications', style: AppTheme.getHeadingStyle(_currentTheme)),
        backgroundColor: _currentTheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.notifications, color: _currentTheme.primary),
              title: Text('Budget Alerts', style: TextStyle(color: _currentTheme.onSurface)),
              subtitle: Text('Get notified when you exceed 80% of your budget'),
            ),
            ListTile(
              leading: Icon(Icons.schedule, color: _currentTheme.primary),
              title: Text('Bill Reminders', style: TextStyle(color: _currentTheme.onSurface)),
              subtitle: Text('Never miss a payment again'),
            ),
            ListTile(
              leading: Icon(Icons.trending_up, color: _currentTheme.primary),
              title: Text('Weekly Reports', style: TextStyle(color: _currentTheme.onSurface)),
              subtitle: Text('Get insights about your spending patterns'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: _currentTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Settings', style: AppTheme.getHeadingStyle(_currentTheme)),
        backgroundColor: _currentTheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.palette, color: _currentTheme.primary),
              title: Text('Theme', style: TextStyle(color: _currentTheme.onSurface)),
              subtitle: Text(AppTheme.themeNames[_selectedThemeIndex]),
              onTap: () {
                Navigator.pop(context);
                _showThemeSelector();
              },
            ),
            ListTile(
              leading: Icon(Icons.account_circle, color: _currentTheme.primary),
              title: Text('Profile', style: TextStyle(color: _currentTheme.onSurface)),
              subtitle: Text('Edit your profile information'),
            ),
            ListTile(
              leading: Icon(Icons.security, color: _currentTheme.primary),
              title: Text('Privacy', style: TextStyle(color: _currentTheme.onSurface)),
              subtitle: Text('Manage your privacy settings'),
            ),
            ListTile(
              leading: Icon(Icons.help, color: _currentTheme.primary),
              title: Text('Help & Support', style: TextStyle(color: _currentTheme.onSurface)),
              subtitle: Text('Get help and contact support'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: _currentTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showAddIncomeDialog() {
    final incomeController = TextEditingController();
    final colorScheme = _currentTheme;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          final isValid = incomeController.text.isNotEmpty && double.tryParse(incomeController.text) != null;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            backgroundColor: colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Themed icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.13),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.attach_money, color: colorScheme.primary, size: 32),
                ),
                const SizedBox(height: 16),
                Text('Add Income',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Increase your balance',
                  style: TextStyle(
                    fontSize: 15,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                // Themed input
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: incomeController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.3)),
                          filled: true,
                          fillColor: colorScheme.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'LE',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('This will increase your available balance.',
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.6)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: isValid ? () async {
                  final newIncome = double.parse(incomeController.text);
                  await FirestoreService.setBalance(
                    total: _totalBalance + newIncome,
                    monthlyBudgetLeft: _monthlyBudgetLeft + newIncome,
                    monthlyBudgetTarget: _monthlyBudgetTarget + newIncome,
                    spent: _spent,
                  );
                  Navigator.pop(context);
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: isValid ? 4 : 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                ),
                child: const Text('Add', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMonthlyPlanDialog() {
    final plan = _generateMonthlyPlan();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Your Monthly Plan', style: AppTheme.getHeadingStyle(_currentTheme)),
        backgroundColor: _currentTheme.surface,
        content: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested Monthly Budget: LE${plan['suggestedBudget'].toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text('Recommendations:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ...plan['recommendations'].map((rec) => ListTile(
                  leading: const Icon(Icons.lightbulb_outline, color: Colors.teal, size: 24),
                  title: Text(rec, style: const TextStyle(fontSize: 16)),
                )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(fontSize: 18))),
        ],
      ),
    );
  }

  Map<String, dynamic> _generateMonthlyPlan() {
    final monthly = widget.surveyResults['On average, how much do you spend monthly?'] as String? ?? 'LE500-LE1000';
    final goals   = List<String>.from(widget.surveyResults['Financial Goals'] ?? []);
    double suggested = 0.0;
    if      (monthly == 'Less than LE500')    suggested = 400;
    else if (monthly == 'LE500-LE1000')       suggested = 750;
    else if (monthly == 'LE1000-LE2000')      suggested = 1500;
    else if (monthly == 'More than LE2000')   suggested = 2500;

    final recs = <String>[];
    if (goals.contains('Save for a big purchase'))    recs.add('Consider saving 20% of your income for a big purchase.');
    if (goals.contains('Build an emergency fund'))    recs.add('Aim to save at least 3-6 months of living expenses.');
    if (goals.contains('Pay off debt'))               recs.add('Allocate extra funds to pay off high-interest debt.');

    return {
      'suggestedBudget': suggested,
      'recommendations': recs,
    };
  }

  void _showBudgetDialog(int index) {
    final budgetController = TextEditingController(
      text: (_categories[index]['budget'] as double) == 0.0
          ? ''
          : (_categories[index]['budget'] as double).abs().toString(),
    );
    final cat = _categories[index];
    final catColor = cat['color'] as Color;
    final catIcon = cat['icon'] as IconData;
    final catName = cat['name'] as String;
    final catId = cat['id'];
    double getCurrentBudget() {
      final txt = budgetController.text;
      final parsed = double.tryParse(txt);
      return (parsed != null && parsed > 0) ? parsed : (cat['budget'] as double).abs();
    }
    final currentBudget = getCurrentBudget();
    bool isEditing = false;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
        content: SizedBox(
            width: MediaQuery.of(context).size.width * .85,
          child: Column(
              mainAxisSize: MainAxisSize.min,
            children: [
                // Large icon in colored circle
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(catIcon, color: catColor, size: 36),
                  ),
                ),
                const SizedBox(height: 10),
                Text(catName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                // Budget value and LE centered as a unit under icon and name, pen/check at far right on same line
                SizedBox(
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!isEditing)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                            Text(
                              budgetController.text.isEmpty ? '0.0' : budgetController.text,
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Text('LE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                          ],
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 160,
                    child: TextField(
                      controller: budgetController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                                autofocus: true,
                                textAlign: TextAlign.center,
                      decoration: InputDecoration(
                                  border: UnderlineInputBorder(),
                        hintText: 'Enter Amount',
                                  hintStyle: TextStyle(fontSize: 22, color: Colors.grey[400]),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                                ),
                                onSubmitted: (_) => setState(() => isEditing = false),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text('LE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      Positioned(
                        right: 0,
                        child: IconButton(
                          icon: Icon(isEditing ? Icons.check : Icons.edit, color: catColor, size: 22),
                          onPressed: () => setState(() => isEditing = !isEditing),
                          tooltip: isEditing ? 'Done' : 'Edit Budget',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // Modern Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        child: Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          elevation: 4,
                          shadowColor: Colors.redAccent.withOpacity(0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          if (catId != null) {
                            await FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .collection('categories')
                              .doc(catId)
                              .delete();
                          }
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.check, color: Colors.white),
                        label: Text('Save Budget', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: catColor,
                          elevation: 4,
                          shadowColor: catColor.withOpacity(0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                  if (budgetController.text.isNotEmpty) {
                            final enteredBudget = double.parse(budgetController.text).abs();
                            if (catId != null) {
                              await FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .collection('categories')
                                .doc(catId)
                                .set({'budget': enteredBudget}, SetOptions(merge: true));
                            }
                    Navigator.pop(context);
                  }
                },
                ),
              ),
            ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    IconData selectedIcon  = Icons.add;
    Color selectedColor    = Colors.grey;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add New Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Category Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Choose an Icon:', style: TextStyle(fontSize: 16)),
              Wrap(
                spacing: 10,
                children: [
                  Icons.shopping_cart,
                  Icons.movie,
                  Icons.receipt,
                  Icons.local_gas_station,
                  Icons.fastfood,
                  Icons.medical_services,
                  Icons.school,
                  Icons.flight,
                  Icons.fitness_center,
                  Icons.music_note,
                ].map((icon) {
                  return IconButton(
                    icon: Icon(icon),
                    color: selectedIcon == icon ? Colors.blue : Colors.grey,
                    onPressed: () => setState(() => selectedIcon = icon),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text('Choose a Color:', style: TextStyle(fontSize: 16)),
              Wrap(
                spacing: 10,
                children: [
                  Colors.red,
                  Colors.green,
                  Colors.blue,
                  Colors.purple,
                  Colors.orange,
                ].map((color) {
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedColor == color ? Colors.black : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  // Save new category to Firestore
                  await FirestoreService.addCategory(
                    name: nameController.text,
                    color: selectedColor.value,
                    icon: selectedIcon.codePoint,
                  );
                  // Do NOT update _categories locally. Wait for Firestore stream to update it.
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToExpansesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpansesScreen(
          categories: _categories,
          onExpenseAdded: (catName, amount, isNotPriority, productName, mandatoryLevel) async {
            final cost = amount.abs();
            setState(() {
              // Update spent amount
              _spent += cost;

              // Update monthly budget left
              _monthlyBudgetLeft = (_monthlyBudgetLeft - cost).clamp(0.0, double.infinity);
            });

            // Persist to Firestore
            final cat = _categories.firstWhere(
              (c) => c['name'] == catName && c['id'] != null,
              orElse: () => {'id': null},
            );
            print('[DEBUG] Using catId: ${cat['id']} for category: $catName');
            try {
              print('[DEBUG] Calling addTransaction with: catId='+cat['id'].toString()+', amount='+(-cost).toString()+', notPriority='+isNotPriority.toString()+', productName='+productName.toString()+', catName='+catName);
              await FirestoreService.addTransaction(
                catId       : cat['id']       as String?,
                amount      : -cost,
                notPriority : isNotPriority,
                productName : productName,
                catName     : catName,
              );
              print('✅ addTransaction succeeded');
            } catch (e, st) {
              print('❌ addTransaction failed: $e\n$st');
            }

            _resetDaysLeft();
          },
          themeIndex: _selectedThemeIndex,
        ),
      ),
    );
  }

  // ───────────────────────────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    // status bar
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: _currentTheme.background,
      statusBarIconBrightness: _currentTheme.brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
      statusBarBrightness: _currentTheme.brightness == Brightness.dark
          ? Brightness.dark
          : Brightness.light,
    ));

    return SafeArea(
      child: Scaffold(
        backgroundColor: _currentTheme.brightness == Brightness.dark
            ? Color(0xFF1A202C)
            : Color(0xFFE0E5EC),
        body: Stack(
          children: [
            // Scrollable content (bottom layer, not Positioned)
            SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Animated spacing to smoothly slide content up
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: (_goalsBannerVisible ? 256.0 - _bannerOffset : 140.0 - _bannerOffset).clamp(0.0, double.infinity),
                    curve: Curves.ease,
                  ),
                    // Your existing content below
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
                      child: Column(
                      children: [
                          _buildWideBudgetCard(
                            leftTitle: 'Monthly Budget',
                            leftValue: '${_totalBalance.toStringAsFixed(0)} LE',
                            leftIcon: Icons.account_balance_wallet,
                            leftAccent: _currentTheme.primary,
                            rightTitle: 'Days Left',
                            rightValue: '$_daysLeft days',
                            rightAccent: _currentTheme.primary.withOpacity(0.8),
                            showRightIcon: false,
                          ),
                          SizedBox(height: 18),
                          _buildWideBudgetCard(
                            leftTitle: 'Budget Left',
                            leftValue: '${_monthlyBudgetLeft.toStringAsFixed(0)} LE',
                            leftIcon: Icons.savings,
                            leftAccent: _currentTheme.secondary,
                            leftPercentage: '${((_monthlyBudgetLeft / _totalBalance) * 100).toStringAsFixed(0)}%',
                            rightTitle: 'Spending',
                            rightValue: '${_spent.toStringAsFixed(0)} LE',
                            rightAccent: _currentTheme.tertiary,
                            rightPercentage: '${((_spent / _totalBalance) * 100).toStringAsFixed(0)}%',
                            showRightIcon: false,
                            percentInline: true,
                          ),
                      ],
                    ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Quick Actions',
                        style: AppTheme.getHeadingStyle(_currentTheme).copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _currentTheme.onBackground,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildQuickActionButton(
                          Icons.attach_money,
                          'Add Income',
                          _currentTheme.secondary,
                          _showAddIncomeDialog,
                        ),
                        _buildQuickActionButton(
                          Icons.account_balance_wallet,
                          'Add Expense',
                          _currentTheme.primary,
                          _navigateToExpansesScreen,
                        ),
                        _buildQuickActionButton(Icons.bar_chart, 'Charts', _currentTheme.secondary, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChartsScreen(
                                themeIndex: _selectedThemeIndex,
                                categories: _categories,
                              ),
                            ),
                          );
                        }),
                        _buildQuickActionButton(Icons.bar_chart, 'Reports', _currentTheme.tertiary, () {
                          Navigator.pushNamed(context, '/reports');
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Monthly Expenses Overview (replace with Pie Chart for Category Breakdown)
                    // Removed the 'Savings Graph' title and extra spacing
                    // Chart Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        height: 455, // Increased height by 35 pixels to fit all charts
                        decoration: BoxDecoration(
                          color: _currentTheme.brightness == Brightness.dark
                              ? const Color(0xFF23272F)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: _currentTheme.brightness == Brightness.dark
                                  ? Colors.black.withOpacity(0.18)
                                  : Colors.grey.withOpacity(0.13),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Chart title
                            Text(
                              _selectedChartType == improved.ChartType.line
                                  ? 'Savings Trend'
                                  : _selectedChartType == improved.ChartType.pie
                                      ? 'Category Breakdown'
                                      : _selectedChartType == improved.ChartType.bar
                                          ? 'Last month category expanses'
                                          : 'Priority vs Non-Priority',
                              style: AppTheme.getHeadingStyle(_currentTheme).copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _currentTheme.onBackground,
                              ),
                            ),
                            SizedBox(height: 12),
                            // Chart switching logic
                            Expanded(
                              child: _selectedChartType == improved.ChartType.line
                                  ? FutureBuilder<List<Map<String, dynamic>>>(
                                      future: FirestoreService.getSavingsChartData(),
                                      builder: (context, snapshot) {
                                        List<double> savingsData = [400, 1800, 800, 1600, 1000, 2000];
                                        List<String> monthLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                          final data = snapshot.data!;
                                          savingsData = data.map((e) => (e['amount'] as num).toDouble()).toList();
                                          monthLabels = data.map((e) {
                                            final parts = (e['month'] as String).split('-');
                                            final monthNum = int.parse(parts[1]);
                                            return ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][monthNum-1];
                                          }).toList();
                                        }
                                        return FinFlowLineChart(
                                          savingsData: savingsData,
                                          monthLabels: monthLabels,
                                          theme: _currentTheme,
                                        );
                                      },
                                    )
                                  : _selectedChartType == improved.ChartType.pie
                                      ? CategoryPieChart(
                                          categories: _categories,
                                          theme: _currentTheme,
                                          size: 220,
                                        )
                                      : _selectedChartType == improved.ChartType.bar
                                          ? LastMonthCategoryBarChart(
                                              categories: _categories,
                                              theme: _currentTheme,
                                              height: 260,
                                            )
                                          : Container(
                                              height: 220,
                                              alignment: Alignment.center,
                                              child: Text(
                                                'Coming soon...',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: _currentTheme.onBackground.withOpacity(0.5),
                                                ),
                                              ),
                                            ),
                            ),
                            SizedBox(height: 18),
                            Center(
                              child: improved.ChartTypeSelector(
                                selectedType: _selectedChartType,
                                onTypeChanged: (type) => setState(() => _selectedChartType = type),
                                theme: _currentTheme,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Expense Categories
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Expense Categories',
                        style: AppTheme.getHeadingStyle(_currentTheme).copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _currentTheme.onBackground,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 15,
                        runSpacing: 20,
                      children: (() {
                        // Sort categories: defaults first, then user-added, then 'Add Category' last
                        final defaultNames = ['Bills', 'Groceries', 'Food', 'Entertainment', 'Fashion'];
                        final defaults = _categories.where((c) => defaultNames.contains(c['name'])).toList();
                        final addCategory = _categories.where((c) => c['name'] == 'Add Category').toList();
                        final userAdded = _categories.where((c) => !defaultNames.contains(c['name']) && c['name'] != 'Add Category').toList();
                        final sorted = [...defaults, ...userAdded, ...addCategory];
                        return sorted.map((cat) {
                          return GestureDetector(
                            onTap: () => cat['name'] == 'Add Category'
                                ? _showAddCategoryDialog()
                                : _showBudgetDialog(_categories.indexOf(cat)),
                            child: _buildCategoryBox(
                              cat['name'] as String,
                              cat['icon'] as IconData,
                              cat['color'] as Color,
                              // Only show budget if not 'Add Category', and always show absolute value
                              cat['name'] == 'Add Category'
                                  ? ''
                                  : '${(cat['budget'] as double).abs().toStringAsFixed(2)} LE',
                            ),
                          );
                        }).toList();
                      })(),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Recent Transactions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Transactions',
                            style: AppTheme.getHeadingStyle(_currentTheme).copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _currentTheme.onBackground,
                            ),
                          ),
                          Container(
                            decoration: AppTheme.getGlassCardDecoration(_currentTheme),
                            child: DropdownButton<String>(
                            value: _selectedFilter,
                            underline: SizedBox(), // Remove the underline
                            alignment: Alignment.center, // Center the selected value
                              items: ['All', ..._categories.where((c) => c['name'] != 'Add Category').map((c) => c['name'] as String)]
                                  .map((v) => DropdownMenuItem(
                                    value: v,
                                  alignment: Alignment.center, // Center dropdown items
                                  child: Center(
                                    child: Text(
                                      v,
                                      style: TextStyle(color: _currentTheme.onBackground),
                                      textAlign: TextAlign.center,
                                    ),
                                    ),
                                  ))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedFilter = v!),
                              dropdownColor: _currentTheme.surface,
                              style: TextStyle(color: _currentTheme.onBackground),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: _recentTransactions
                          .where((t) => _selectedFilter == 'All' || t['category'] == _selectedFilter)
                        .take(5)
                          .map((t) => _buildTransactionItem(
                        t['category'] as String,
                        '-${(t['amount'] as double).toStringAsFixed(2)} LE',
                        t['icon'] as IconData,
                        t['color'] as Color,
                        t['isNotPriority'] as bool,
                        t['productName'] as String?,
                      ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            // Banner (top layer, always interactive when visible)
            IgnorePointer(
              ignoring: _bannerOpacity == 0.0,
              child: Opacity(
                opacity: _bannerOpacity,
                child: Transform.translate(
                  offset: Offset(0, -_bannerOffset),
                  child: Container(
                    height: _goalsBannerVisible ? 256 : 140,
                    decoration: BoxDecoration(
                      gradient: AppTheme.getPrimaryGradient(_currentTheme),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // greeting + icons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _username.isNotEmpty
                                    ? 'Hi, $_username!'
                                    : (_firstName.isNotEmpty || _lastName.isNotEmpty)
                                        ? 'Hi, $_firstName!'
                                    : 'Hi!',
                                style: AppTheme.getHeadingStyle(_currentTheme).copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.notifications, color: Colors.white),
                                    onPressed: () {
              Navigator.push(
                context,
                                        MaterialPageRoute(builder: (_) => NotificationsPage(themeIndex: _selectedThemeIndex)),
                    );
                  },
                ),
                                  IconButton(
                                    icon: Icon(Icons.settings, color: Colors.white),
                                    onPressed: () {
              Navigator.push(
                context,
                                        MaterialPageRoute(
                                          builder: (_) => SettingsPage(
                                            currentThemeIndex: _selectedThemeIndex,
                                            onThemeChanged: (i) {
                                              setState(() => _selectedThemeIndex = i);
                                              widget.onThemeUpdated?.call(i);
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Retractable goals section
                          if (_goalsBannerVisible) ...[
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Financial Goals',
                                  style: AppTheme.getHeadingStyle(_currentTheme).copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.keyboard_arrow_up, color: Colors.white),
                                  onPressed: () => setState(() => _goalsBannerVisible = false),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: FirestoreService.getFinancialGoals(),
                              builder: (context, goalsSnap) {
                                if (!goalsSnap.hasData || goalsSnap.data!.isEmpty) {
                                  return Text('No goals set', style: TextStyle(color: Colors.white));
                                }
                                return FutureBuilder<List<Map<String, dynamic>>>(
                                  future: FirestoreService.getSavingsChartData(),
                                  builder: (context, savingsSnap) {
                                    double latestSavings = 0;
                                    if (savingsSnap.hasData && savingsSnap.data!.isNotEmpty) {
                                      // Use the latest month
                                      latestSavings = (savingsSnap.data!.last['amount'] as num).toDouble();
                                    }
                                    return Column(
                                      children: goalsSnap.data!.take(2).map((goal) {
                                        final target = (goal['target'] as num?)?.toDouble() ?? 1;
                                        final progress = (target > 0) ? (latestSavings / target * 100).clamp(0, 100) : 0.0;
                                        return _buildGoalProgress(goal['name'] ?? '', progress.toDouble());
                                      }).toList(),
                                    );
                                  },
                                );
                              },
                            ),
                          ] else ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Financial Goals',
                                  style: AppTheme.getHeadingStyle(_currentTheme).copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.white),
                                  onPressed: () => setState(() => _goalsBannerVisible = true),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Bottom navigation handled by NavigationWrapper
      ),
    );
  }

  // ───────────────────────────────────────────── helper widgets ────────────────

  Widget _originalOverviewCard({required String title, required String value, required Color color, double? minWidth}) {
    return Container(
      constraints: BoxConstraints(minHeight: 90, minWidth: minWidth != null ? MediaQuery.of(context).size.width * minWidth : 0),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
    child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
        ],
      ),
    ),
  );
  }

  Widget _buildQuickActionButton(
      IconData icon, String label, Color color, VoidCallback onPressed) =>
      GestureDetector(
        onTap: onPressed,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.transparent,
                child: Icon(icon, color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTheme.getBodyStyle(_currentTheme).copyWith(
                color: _currentTheme.onBackground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _buildTransactionItem(
      String category,
      String amount,
      IconData icon,
      Color color,
      bool isNotPriority,
      String? productName) {
    final isUnknown = category == 'Unknown' || category.isEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: AppTheme.getGlassCardDecoration(_currentTheme),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isUnknown ? Colors.blueGrey : color,
          child: Icon(
            isUnknown ? Icons.add : icon,
            color: Colors.white,
          ),
        ),
        title: Text(
          isNotPriority && productName != null
              ? productName
              : (isUnknown ? 'Transaction made' : category),
          style: AppTheme.getBodyStyle(_currentTheme).copyWith(
            color: _currentTheme.onBackground,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: null,
        trailing: Text(
          amount,
          style: AppTheme.getBodyStyle(_currentTheme).copyWith(
            color: isNotPriority ? Colors.grey : _currentTheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      );
  }

  Widget _buildCategoryBox(String name, IconData icon, Color color, String budget) =>
      Container(
        width: (MediaQuery.of(context).size.width - 62) / 3, // Fit exactly 3 cards
        height: 120,
        decoration: AppTheme.getGlassCardDecoration(_currentTheme),
    child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
      children: [
            Icon(icon, color: color, size: 35),
            const SizedBox(height: 8),
            Text(
              name,
              style: AppTheme.getBodyStyle(_currentTheme).copyWith(
                color: _currentTheme.onBackground,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (budget.isNotEmpty) ...[
        const SizedBox(height: 5),
              Text(
                budget,
                style: AppTheme.getBodyStyle(_currentTheme).copyWith(
                  color: _currentTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
        ),
                textAlign: TextAlign.center,
              ),
            ],
      ],
    ),
  );

  Widget _buildGoalProgress(String goal, double progress) {
    final isComplete = progress >= 100.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isComplete ? Colors.greenAccent.withOpacity(0.55) : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: isComplete ? Border.all(color: Colors.green, width: 2) : null,
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: isComplete ? Colors.white : Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              goal,
              style: AppTheme.getBodyStyle(_currentTheme).copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          // Percentage display
          Text(
            '${progress.clamp(0, 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideBudgetCard({
    required String leftTitle,
    required String leftValue,
    required IconData leftIcon,
    required Color leftAccent,
    required String rightTitle,
    required String rightValue,
    required Color rightAccent,
    String? leftPercentage,
    String? rightPercentage,
    bool showRightIcon = true,
    bool percentInline = false,
  }) {
    final isDark = _currentTheme.brightness == Brightness.dark;
    final surfaceColor = isDark ? Color(0xFF2D3748) : Color(0xFFE0E5EC);
    final lightShadow = isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.7);
    final darkShadow = isDark ? Colors.white.withOpacity(0.1) : Color(0xFFA3B1C6).withOpacity(0.6);
    final numberColor = isDark ? Colors.white : Colors.black;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: double.infinity,
        height: 120,
        margin: EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: lightShadow,
              offset: Offset(-6, -6),
              blurRadius: 12,
            ),
            BoxShadow(
              color: darkShadow,
              offset: Offset(6, 6),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          children: [
            // Left section (wider)
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: leftAccent.withOpacity(0.12),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: leftAccent.withOpacity(0.13),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(10),
                      child: Icon(leftIcon, color: leftAccent, size: 24),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leftTitle,
                            style: TextStyle(
                              color: _currentTheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: leftTitle == 'Monthly Budget' ? 17 : leftTitle == 'Budget Left' ? 18 : 17,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8),
                          percentInline && leftPercentage != null && leftPercentage.isNotEmpty
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    _buildValueWithCurrency(leftValue, numberColor),
                                    SizedBox(width: 6),
                                    Text(
                                      leftPercentage,
                                      style: TextStyle(
                                        color: leftAccent,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildValueWithCurrency(leftValue, numberColor),
                                    if (leftPercentage != null && leftPercentage.isNotEmpty) ...[
                                      SizedBox(height: 2),
                                      Text(
                                        leftPercentage,
                                        style: TextStyle(
                                          color: leftAccent,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Divider (much further right)
            Container(
              height: 60,
              child: VerticalDivider(
                color: Colors.grey.withOpacity(0.18),
                thickness: 1.2,
                width: 1.2,
              ),
            ),
            // Right section (narrower)
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rightTitle,
                      style: TextStyle(
                        color: _currentTheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),
                    percentInline && rightPercentage != null && rightPercentage.isNotEmpty
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              _buildValueWithCurrency(rightValue, numberColor),
                              SizedBox(width: 8),
                              Text(
                                rightPercentage,
                                style: TextStyle(
                                  color: rightAccent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildValueWithCurrency(rightValue, numberColor),
                              if (rightPercentage != null && rightPercentage.isNotEmpty) ...[
                                SizedBox(height: 2),
                                Text(
                                  rightPercentage,
                                  style: TextStyle(
                                    color: rightAccent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build value with small currency
  Widget _buildValueWithCurrency(String value, Color numberColor) {
    final match = RegExp(r'([\d,\.]+)\s*LE').firstMatch(value);
    if (match != null) {
      final number = match.group(1) ?? value;
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            number,
            style: TextStyle(
              color: numberColor,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          SizedBox(width: 2),
          Text(
            ' LE',
            style: TextStyle(
              color: numberColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      );
    } else {
      return Text(
        value,
        style: TextStyle(
          color: numberColor,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      );
    }
  }
}
