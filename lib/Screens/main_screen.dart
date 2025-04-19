import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // status bar style
import 'dart:async';
import 'notes_screen.dart';
import 'expanses_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects_flutter/services/firestore_services.dart';

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

class _MainScreenState extends State<MainScreen> {
  final ScrollController _scrollController = ScrollController();
  double _bannerOpacity = 1.0;
  double _bannerOffset = 0.0;

  String _firstName = '';
  String _lastName  = '';

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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetch first/last name
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .then((docSnapshot) {
        if (docSnapshot.exists) {
          setState(() {
            _firstName = docSnapshot.get('firstName') ?? '';
            _lastName  = docSnapshot.get('lastName')  ?? '';
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

  void _showSetTotalBalanceDialog() {
    final totalBalanceController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter Total Balance'),
        content: TextField(
          controller: totalBalanceController,
          decoration: InputDecoration(
            hintText: 'Enter Total Balance',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (totalBalanceController.text.isNotEmpty) {
                final newVal = double.parse(totalBalanceController.text);
                // write up to Firestore…
                await FirestoreService.setBalance(
                    total: newVal,
                    monthlyBudgetLeft: newVal,
                    monthlyBudgetTarget: newVal,
                    spent: newVal,
                );
                // and let your existing balanceStream() subscription pull the new values back into state
                Navigator.pop(context);
              }
            },
            child: const Text('Set'),
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
        title: const Text('Your Monthly Plan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
              // 1) pull it out of your monthly‑left bucket
              _monthlyBudgetLeft = _monthlyBudgetLeft.clamp(0.0, _monthlyBudgetLeft);
              _spent += cost.clamp(0.0, _spent);

              // your category‑budget adjustment stays the same
              final idx = _categories.indexWhere((c) => c['name'] == catName);
              if (idx != -1 && (_categories[idx]['budget'] as double) > 0) {
                _categories[idx]['budget'] =
                    (_categories[idx]['budget'] as double) - cost;
              }

              // and keep your transaction list insertion the same
              _recentTransactions.insert(0, {
                'category'     : isNotPriority && catName == 'None' ? productName! : catName,
                'amount'       : cost,
                'icon'         : isNotPriority
                    ? Icons.remove
                    : _categories.firstWhere((c) => c['name'] == catName)['icon'],
                'color'        : isNotPriority
                    ? Colors.grey
                    : _categories.firstWhere((c) => c['name'] == catName)['color'],
                'isNotPriority': isNotPriority,
                'productName'  : productName,
              });
            });

            // then persist to Firestore as before
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            // banner
            Transform.translate(
              offset: Offset(0, -_bannerOffset),
              child: Opacity(
                opacity: _bannerOpacity,
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo[900]!, Colors.purple[800]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.2, 0.8],
                    ),
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
                              (_firstName.isNotEmpty || _lastName.isNotEmpty)
                                  ? 'Hi, $_firstName $_lastName!'
                                  : 'Hi!',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications, color: Colors.white),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.settings, color: Colors.white),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text('Financial Goals',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 10),
                        if (widget.selectedGoals.isNotEmpty)
                          ...widget.selectedGoals.map((g) => _buildGoalProgress(g, 50)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // scrollable content
            SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 270),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // top cards
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _showSetTotalBalanceDialog,
                          child: _buildOverviewCard(
                            'Total Monthly Budget',
                            'EGP ${_totalBalance.toStringAsFixed(2)}',
                            Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildOverviewCard(
                          'Monthly Budget Left',
                          'EGP ${_monthlyBudgetLeft.toStringAsFixed(2)}',
                          Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildOverviewCard(
                      'Spent',
                      'EGP ${_spent.toStringAsFixed(2)}',
                      Colors.black),
                  const SizedBox(height: 20),

                  // quick actions
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Quick Actions',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickActionButton(Icons.add, 'Add Expense', Colors.blue, _navigateToExpansesScreen),
                      _buildQuickActionButton(Icons.attach_money, 'Add Income', Colors.green, () {}),
                      _buildQuickActionButton(Icons.calendar_today, 'Monthly Plan', Colors.teal, _showMonthlyPlanDialog),
                      _buildQuickActionButton(Icons.bar_chart, 'Reports', Colors.orange, () {
                        Navigator.pushNamed(context, '/reports');
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // placeholder graph
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Monthly Expenses Graph',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/graph_placeholder.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // categories
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Expense Categories',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 10,
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
                                ? 'LE${(cat['budget'] as double).toStringAsFixed(2)}'
                                : '',
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // recent transactions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recent Transactions',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        DropdownButton<String>(
                          value: _selectedFilter,
                          items: ['All', 'Groceries', 'Entertainment', 'Bills']
                              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedFilter = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: _recentTransactions
                        .where((t) => _selectedFilter == 'All' || t['category'] == _selectedFilter)
                        .map((t) => _buildTransactionItem(
                      t['category']      as String,
                      '-LE${(t['amount'] as double).toStringAsFixed(2)}',
                      t['icon']          as IconData,
                      t['color']         as Color,
                      t['isNotPriority'] as bool,
                      t['productName']   as String?,
                    ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),

        // bottom nav
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home),      label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.notes),     label: 'Notes'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
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
            }
          },
        ),
      ),
    );
  }

  // ───────────────────────────────────────────── helper widgets ────────────────

  Widget _buildOverviewCard(String title, String value, Color color) => Card(
    elevation: 4,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    ),
  );

  Widget _buildQuickActionButton(
      IconData icon, String label, Color color, VoidCallback onPressed) =>
      GestureDetector(
        onTap: onPressed,
        child: Column(
          children: [
            CircleAvatar(radius: 40, backgroundColor: color, child: Icon(icon, color: Colors.white, size: 40)),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
      );

  Widget _buildTransactionItem(
      String category,
      String amount,
      IconData icon,
      Color color,
      bool isNP,
      String? productName) =>
      ListTile(
        leading: Icon(icon, color: isNP ? Colors.grey : color),
        title: Text(isNP && category == 'None' ? productName! : category,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        trailing:
        Text(amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
      );

  Widget _buildGoalProgress(String goal, int progress) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(goal, style: const TextStyle(fontSize: 16, color: Colors.white)),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 10),
      ],
    ),
  );

  Widget _buildCategoryBox(String name, IconData icon, Color color, String remaining) => Container(
    width: 140,
    height: 140,
    decoration: BoxDecoration(color: color.withOpacity(.2), shape: BoxShape.circle),
    child: ClipOval(
      child: Center(
        child: name == 'Add Category'
            ? Icon(icon, size: 50, color: color)
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 5),
            Text(name,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
            if (remaining.isNotEmpty) ...[
              const SizedBox(height: 0),
              Text(remaining,
                  style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
            ]
          ],
        ),
      ),
    ),
  );
}