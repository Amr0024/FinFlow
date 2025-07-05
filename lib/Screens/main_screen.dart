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
import 'package:collection/collection.dart';

class MainScreen extends StatefulWidget {
  final List<String> selectedGoals; // Selected financial goals
  final Map<String, dynamic> surveyResults; // Survey results

  const MainScreen({
    super.key,
    required this.selectedGoals,
    required this.surveyResults,
  });


  @override
  _MainScreenState createState() => _MainScreenState();
}

double _safePct(double part, double total) {
  // return 0 if total is zero or negative, otherwise the real %
  if (total <= 0) return 0;
  return (part / total) * 100;
}

class _MainScreenState extends State<MainScreen> {
  Timer? _midnightTimer;

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
  int _selectedThemeIndex = 0; // Default to original theme
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
    _scrollController.addListener(_onScroll);
    _initDaysLeft();
    _scheduleMidnightTick();

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
          _spent = (data['spent'] ?? 0).toDouble();
        });
      });

      // 3) recent transactions (last20)
      _trxSub = FirestoreService.recentTxStream(20).listen((snap) {
        setState(() {
          _recentTransactions = snap.docs.map((d) {
            final data = d.data();
            final isNP = data['notPriority'] as bool? ?? false;
            return {
              'category'     : data['catName']     as String? ?? 'Unknown',
              'amount'       : (data['amount']     as num?)?.abs().toDouble() ?? 0.0,
              'icon'         : isNP
                  ? Icons.remove
                  : IconData(data['icon'] as int? ?? 0,
                  fontFamily: 'MaterialIcons'),
              'color'        : isNP
                  ? Colors.grey
                  : Color(data['color'] as int? ?? 0xFF000000),
              'isNotPriority': isNP,
              'productName'  : data['productName'],
            };
          }).toList();
        });
      });
    }
  }

  void _initDaysLeft() {
    final now = DateTime.now();

    // First run or we switched to a new month?
    if (_lastResetDate == null ||
        now.year != _lastResetDate!.year ||
        now.month != _lastResetDate!.month) {

      // 1️⃣  Mark the first day of this month as the reset point
      _lastResetDate = DateTime(now.year, now.month, 1);

      // 2️⃣  Compute how many days remain
      final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
      _daysLeft = daysInMonth - now.day + 1;      // inclusive of today
    } else {
      // We’re still in the same month → just recalc
      final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
      _daysLeft = daysInMonth - now.day + 1;
    }
  }

  // Schedules a one-shot timer that fires 1 second after the next midnight.
  void _scheduleMidnightTick() {
    // cancel any leftover timer just in case
    _midnightTimer?.cancel();

    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = nextMidnight.difference(now) + const Duration(seconds: 1);

    _midnightTimer = Timer(durationUntilMidnight, () {
      // refresh the counter and rebuild the UI
      setState(_initDaysLeft);

      // schedule the NEXT midnight
      _scheduleMidnightTick();
    });
  }

  void _resetDaysLeft() {
    setState(() {
      _lastResetDate = DateTime.now();
      _daysLeft = 30;
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Income', style: AppTheme.getHeadingStyle(_currentTheme)),
        backgroundColor: _currentTheme.surface,
        content: TextField(
          controller: incomeController,
          decoration: InputDecoration(
            hintText: 'Enter Income Amount in LE',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _currentTheme.primary))
          ),
          ElevatedButton(
            onPressed: () async {
              if (incomeController.text.isNotEmpty) {
                final newIncome = double.parse(incomeController.text);
                await FirestoreService.setBalance(
                    total: _totalBalance + newIncome,
                    monthlyBudgetLeft: _monthlyBudgetLeft + newIncome,
                    monthlyBudgetTarget: _monthlyBudgetTarget,
                    spent: _spent,
                );
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
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
          : (_categories[index]['budget'] as double).toString(),
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * .8,
          height: 200,
          child: Column(
            children: [
              Row(
                children: [
                  Icon(_categories[index]['icon'], color: _categories[index]['color'], size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: budgetController,
                      decoration: InputDecoration(
                        hintText: 'Enter Amount',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (budgetController.text.isNotEmpty) {
                    setState(() {
                      _categories[index]['budget'] = double.parse(budgetController.text);
                    });
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _categories[index]['color'],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Set Budget'),
              ),
            ],
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
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _categories.insert(
                      _categories.length - 1,
                      {
                        'name'  : nameController.text,
                        'icon'  : selectedIcon,
                        'color' : selectedColor,
                        'budget': 0.0,
                      },
                    );
                  });
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

              // Update category budget
              final idx = _categories.indexWhere((c) => c['name'] == catName);
              if (idx != -1 && (_categories[idx]['budget'] as double) > 0) {
                _categories[idx]['budget'] =
                    (_categories[idx]['budget'] as double) - cost;
              }

              final matchedCat = _categories.firstWhereOrNull((c) => c['name'] == catName);


              // Add to recent transactions
              _recentTransactions.insert(0, {
                'category'     : isNotPriority && catName == 'None' ? productName! : catName,
                'amount'       : cost,
                'icon' : isNotPriority
                    ? Icons.remove
                    : (matchedCat?['icon'] as IconData?) ?? Icons.help_outline,
                'color' : isNotPriority
                    ? Colors.grey
                    : (matchedCat?['color'] as Color?) ?? Colors.blueGrey,
                'isNotPriority': isNotPriority,
                'productName'  : productName,


              });
            });

            // Persist to Firestore
            final cat = _categories.firstWhere((c) => c['name'] == catName, orElse: () => {'id':null});
            try {
              await FirestoreService.addTransaction(
                catId       : cat['id']       as String?,
                amount      : -cost,
                notPriority : isNotPriority,
                productName : productName,
              );
              print('✅ addTransaction succeeded');
            } catch (e, st) {
              print('❌ addTransaction failed: $e\n$st');
            }

          },
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
            // banner with theme support (from text file)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Transform.translate(
                offset: Offset(0, -_bannerOffset),
                child: Opacity(
                  opacity: _bannerOpacity,
                  child: Container(
                    height: _goalsBannerVisible ? 256 : 120,
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
                                        MaterialPageRoute(builder: (_) => NotificationsPage()),
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
            // scrollable content (from text file)
            Positioned(
              top: _goalsBannerVisible ? 256 : 120,
              left: 0,
              right: 0,
              bottom: 0,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            leftPercentage : '${_safePct(_monthlyBudgetLeft, _totalBalance).toStringAsFixed(0)}%',
                            rightTitle: 'Spending',
                            rightValue: '${_spent.toStringAsFixed(0)} LE',
                            rightAccent: _currentTheme.tertiary,
                            rightPercentage: '${_safePct(_spent, _totalBalance).toStringAsFixed(0)}%',
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
                        _buildQuickActionButton(Icons.attach_money, 'Add Income', Colors.green, _showAddIncomeDialog),
                        _buildQuickActionButton(Icons.account_balance_wallet, 'Add Expense', _currentTheme.primary, _navigateToExpansesScreen),
                        _buildQuickActionButton(Icons.calendar_today, 'Monthly Plan', _currentTheme.secondary, _showMonthlyPlanDialog),
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
                        child: _buildMainChart(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: improved.ChartTypeSelector(
                        selectedType: _selectedChartType,
                        onTypeChanged: (type) => setState(() => _selectedChartType = type),
                        theme: _currentTheme,
                      ),
                    ),
                    const SizedBox(height: 30),

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
                        children: _categories.map((cat) {
                          return GestureDetector(
                            onTap: () => cat['name'] == 'Add Category'
                                ? _showAddCategoryDialog()
                                : _showBudgetDialog(_categories.indexOf(cat)),
                            child: _buildCategoryBox(
                              cat['name'] as String,
                              cat['icon'] as IconData,
                              cat['color'] as Color,
                              (cat['budget'] as double) > 0
                                  ? '${(cat['budget'] as double).toStringAsFixed(2)} LE'
                                  : '',
                            ),
                          );
                        }).toList(),
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
                              items: ['All', ..._categories.where((c) => c['name'] != 'Add Category').map((c) => c['name'] as String)]
                                  .map((v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(
                                      v,
                                      style: TextStyle(color: _currentTheme.onBackground),
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
            ),
          ],
        ),

        // bottom nav with theme support
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          selectedItemColor: _currentTheme.primary,
          unselectedItemColor: _currentTheme.onBackground.withOpacity(0.5),
          backgroundColor: _currentTheme.surface,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home),      label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.notes),     label: 'Notes'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Goals'),
            BottomNavigationBarItem(icon: Icon(Icons.settings),  label: 'Settings'),
          ],
          onTap: (i) {
            if (i == 1) {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => NotesScreen(categories: _categories),
                  transitionsBuilder: (_, animation, __, child) {
                    return SlideTransition(
                      position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                          .chain(CurveTween(curve: Curves.easeInOut))
                          .animate(animation),
                      child: child,
                    );
                  },
                ),
              );
            } else if (i == 2) {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => FinancialGoalsScreen(colorScheme: _currentTheme),
                  transitionsBuilder: (_, animation, __, child) {
                    return SlideTransition(
                      position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                          .chain(CurveTween(curve: Curves.easeInOut))
                          .animate(animation),
                      child: child,
                    );
                  },
                ),
              );
            }
          },
        ),
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
          isUnknown ? 'Transaction made' : (isNotPriority && productName != null ? productName : category),
          style: AppTheme.getBodyStyle(_currentTheme).copyWith(
            color: _currentTheme.onBackground,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: isNotPriority && productName != null
            ? Text(
                category,
                style: AppTheme.getBodyStyle(_currentTheme).copyWith(
                  color: _currentTheme.onBackground.withOpacity(0.7),
                  fontSize: 12,
                ),
              )
            : null,
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
        Text(
          '${progress.toInt()}%',
          style: AppTheme.getBodyStyle(_currentTheme).copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
          ),
        ),
      ],
    ),
  );
  }

  Widget _valueWithPct({
    required String value,
    required String pct,
    required Color pctColor,
    required Color numberColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: numberColor,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
              softWrap: false,
              overflow: TextOverflow.fade,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          pct,
          style: TextStyle(
            color: pctColor,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
          softWrap: false,
          overflow: TextOverflow.fade,
        ),
      ],
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
        height: 110,
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
                              fontSize: 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6),
                          percentInline && leftPercentage != null && leftPercentage.isNotEmpty
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      leftValue,
                                      style: TextStyle(
                                        color: numberColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      leftPercentage,
                                      style: TextStyle(
                                        color: leftAccent,
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
                                    Text(
                                      leftValue,
                                      style: TextStyle(
                                        color: numberColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),
                    percentInline && rightPercentage != null && rightPercentage.isNotEmpty
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                rightValue,
                                style: TextStyle(
                                  color: numberColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
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
                              Text(
                                rightValue,
                                style: TextStyle(
                                  color: numberColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
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

  Widget _buildMainChart() {
    switch (_selectedChartType) {
      case improved.ChartType.line:
        return Center(
          child: FutureBuilder<List<Map<String, dynamic>>>(
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
          ),
        );
      case improved.ChartType.pie:
        return Center(
          child: improved.InteractivePieChart(
            data: improved.ChartDataFactory.pieFromCategories(monthlyReportData, _currentTheme),
            theme: _currentTheme,
            size: 220,
          ),
        );
      case improved.ChartType.bar:
        return Center(
          child: improved.AnimatedBarChart(
            data: improved.ChartDataFactory.barFromNonPriority(monthlyReportData, _currentTheme),
            theme: _currentTheme,
            height: 220,
          ),
        );
      default:
        // Fallback to new line chart if type is not handled
        return Center(
          child: FinFlowLineChart(
            savingsData: [400, 1800, 800, 1600, 1000, 2000],
            monthLabels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
            theme: _currentTheme,
          ),
        );
    }
  }
}
