import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For status bar style
import 'dart:math'; // Import for Random
import 'notes_screen.dart'; // Import the Notes Screen
import 'expanses_screen.dart'; // Import the new Expenses Screen
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
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
  String _lastName = '';

  /// Live data pulled from Firestore
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _recentTransactions = [];

  double _totalBalance   = 0.0;   // from balance/current
  double _monthlyBudget  = 0.0;   // idem
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
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .then((docSnapshot) {
        if (docSnapshot.exists) {
          setState(() {
            _firstName = docSnapshot.get('firstName') ?? '';
            _lastName = docSnapshot.get('lastName') ?? '';
          });
        }
      }).catchError((error) {
        // handle errors
      });
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {

      // --- Categories stream ---
      _catSub = FirestoreService.streamCategories().listen((cats) {
        setState(() => _categories = cats);
      });

      // --- Balance stream ---
      _balSub = FirestoreService.streamBalance().listen((bal) {
        setState(() {
          _totalBalance  = bal['total'] ?? 0.0;
          _monthlyBudget = bal['monthlyBudget'] ?? 0.0;
        });
      });

      // --- Recent transactions stream (last 20) ---
      _trxSub = FirestoreService.streamRecentTransactions().listen((trx) {
        setState(() => _recentTransactions = trx);
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
    setState(() {
      if (_scrollController.offset > 100) {
        _bannerOpacity = 0.0;
        _bannerOffset = 100;
      } else {
        _bannerOpacity = 1.0 - (_scrollController.offset / 100);
        _bannerOffset = _scrollController.offset;
      }
    });
  }

  void _showSetTotalBalanceDialog() {
    TextEditingController totalBalanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (totalBalanceController.text.isNotEmpty) {
                  setState(() {
                    _totalBalance = double.parse(totalBalanceController.text);
                    _monthlyBudget = _totalBalance;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
  }

  void _showMonthlyPlanDialog() {
    Map<String, dynamic> monthlyPlan = _generateMonthlyPlan();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Your Monthly Plan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suggested Monthly Budget: LE${monthlyPlan['suggestedBudget'].toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Recommendations:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ...monthlyPlan['recommendations'].map((recommendation) {
                    return ListTile(
                      leading: const Icon(Icons.lightbulb_outline, color: Colors.teal, size: 24),
                      title: Text(
                        recommendation,
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(fontSize: 18)),
            ),
          ],
        );
      },
    );
  }

  // Replaces references to strings like "$500-$1000" with "LE500-LE1000"
  Map<String, dynamic> _generateMonthlyPlan() {
    // Notice the replacements from "\$20-\$50" to "LE20-LE50", etc.
    String trackingPreference = widget.surveyResults['How often do you want to track your expenses?'] ?? 'Monthly';
    String dailySpending = widget.surveyResults['On average, how much do you spend daily?'] ?? 'LE20-LE50';
    String monthlySpending = widget.surveyResults['On average, how much do you spend monthly?'] ?? 'LE500-LE1000';
    List<String> financialGoals = widget.surveyResults['Financial Goals'] ?? [];

    double suggestedBudget = 0.0;

    // changed from 'Less than $500' => 'Less than LE500'
    if (monthlySpending == 'Less than LE500') {
      suggestedBudget = 400.0;
    } else if (monthlySpending == 'LE500-LE1000') {
      suggestedBudget = 750.0;
    } else if (monthlySpending == 'LE1000-LE2000') {
      suggestedBudget = 1500.0;
    } else if (monthlySpending == 'More than LE2000') {
      suggestedBudget = 2500.0;
    }

    List<String> recommendations = [];
    if (financialGoals.contains('Save for a big purchase')) {
      recommendations.add('Consider saving 20% of your income for a big purchase.');
    }
    if (financialGoals.contains('Build an emergency fund')) {
      recommendations.add('Aim to save at least 3-6 months of living expenses.');
    }
    if (financialGoals.contains('Pay off debt')) {
      recommendations.add('Allocate extra funds to pay off high-interest debt.');
    }

    return {
      'suggestedBudget': suggestedBudget,
      'recommendations': recommendations,
      'trackingPreference': trackingPreference,
    };
  }

  void _showBudgetDialog(int index) {
    TextEditingController budgetController = TextEditingController(
      text: _categories[index]['budget'] == 0.0 ? '' : _categories[index]['budget'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(_categories[index]['icon'], color: _categories[index]['color'], size: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: budgetController,
                        decoration: InputDecoration(
                          hintText: 'Enter Amount',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Set Budget'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog() {
    TextEditingController nameController = TextEditingController();
    IconData selectedIcon = Icons.add;
    Color selectedColor = Colors.grey;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Category Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Choose an Icon:', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
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
                        onPressed: () {
                          setState(() {
                            selectedIcon = icon;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('Choose a Color:', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
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
                        onTap: () {
                          setState(() {
                            selectedColor = color;
                          });
                        },
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
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      setState(() {
                        _categories.insert(
                          _categories.length - 1,
                          {
                            'name': nameController.text,
                            'icon': selectedIcon,
                            'color': selectedColor,
                            'budget': 0.0,
                            'expenses': [],
                          },
                        );
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _navigateToExpansesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpansesScreen(
          categories: _categories,
          onExpenseAdded: (String category, double amount, bool isNotPriority, String? productName, String? mandatoryLevel) {
            setState(() {
              // For your display, changed from -$ to -LE
              _monthlyBudget -= amount;

              if (category != 'None') {
                int categoryIndex = _categories.indexWhere((cat) => cat['name'] == category);
                if (categoryIndex != -1 && _categories[categoryIndex]['budget'] > 0) {
                  _categories[categoryIndex]['budget'] -= amount;
                }
              }

              _recentTransactions.add({
                'category': isNotPriority && category == 'None' ? productName! : category,
                'amount': amount,
                // changed from '-\$' to '-LE' in the final display below
                'icon': isNotPriority ? Icons.remove : _categories.firstWhere((cat) => cat['name'] == category)['icon'],
                'color': isNotPriority ? Colors.grey : _categories.firstWhere((cat) => cat['name'] == category)['color'],
                'isNotPriority': isNotPriority,
                'productName': productName,
              });
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Force the status bar to white with dark icons
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
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
                      tileMode: TileMode.clamp,
                    ),
                  ),
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: const Size(double.infinity, 230)
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Single row with "Hi, X" and top-right icons
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
                                      onPressed: () {
                                        // Handle notifications
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.settings, color: Colors.white),
                                      onPressed: () {
                                        // Navigate to settings
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Financial Goals',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (widget.selectedGoals.isNotEmpty)
                              ...widget.selectedGoals.map((goal) {
                                return _buildGoalProgress(goal, 50);
                              }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 270),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _showSetTotalBalanceDialog,
                          child: _buildOverviewCard('Total Balance', 'EGP ${_totalBalance.toStringAsFixed(2)}', Colors.black),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildOverviewCard('Monthly Budget Left', 'EGP ${_monthlyBudget.toStringAsFixed(2)}', Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // If you have something like "Last Month Savings Progress: 40%" that's text, we keep it
                  _buildOverviewCard('Last Month Savings Progress', '40%', Colors.black),
                  const SizedBox(height: 20),

                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

                  const Text(
                    'Monthly Expenses Graph',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      // If there's a $ in the asset path, remove it; otherwise just keep it
                      child: Image.asset(
                        'assets/images/graph_placeholder.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Expense Categories',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10.0,
                    runSpacing: 20.0,
                    children: _categories.map((category) {
                      return GestureDetector(
                        onTap: () {
                          if (category['name'] == 'Add Category') {
                            _showAddCategoryDialog();
                          } else {
                            _showBudgetDialog(_categories.indexOf(category));
                          }
                        },
                        child: _buildCategoryBox(
                          category['name'],
                          category['icon'],
                          category['color'],
                          category['budget'] > 0 ? 'LE${category['budget'].toStringAsFixed(2)}' : '',
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<String>(
                        value: _selectedFilter,
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value!;
                          });
                        },
                        items: ['All', 'Groceries', 'Entertainment', 'Bills'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: _recentTransactions
                        .where((transaction) => _selectedFilter == 'All' || transaction['category'] == _selectedFilter)
                        .map((transaction) {
                      // Display amount as '-LE...' now
                      final displayAmount = '-LE${transaction['amount'].toStringAsFixed(2)}';
                      return _buildTransactionItem(
                        transaction['category'],
                        displayAmount,
                        transaction['icon'],
                        transaction['color'],
                        transaction['isNotPriority'],
                        transaction['productName'],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notes),
              label: 'Notes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          currentIndex: 0,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            if (index == 1) {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      NotesScreen(categories: _categories),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    final offsetAnimation = animation.drive(tween);
                    return SlideTransition(position: offsetAnimation, child: child);
                  },
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
      String category,
      String amount,
      IconData icon,
      Color color,
      bool isNotPriority,
      String? productName,
      ) {
    return ListTile(
      leading: Icon(
        icon,
        color: isNotPriority ? Colors.grey : color,
      ),
      title: Text(
        isNotPriority && category == 'None' ? productName! : category,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      trailing: Text(
        amount, // e.g. '-LE50.00'
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
      ),
    );
  }

  Widget _buildGoalProgress(String goal, int progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          goal,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
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
    );
  }

  // Changed from \$ to LE in "remainingBudget"
  Widget _buildCategoryBox(String category, IconData icon, Color color, String remainingBudget) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Stack(
          children: [
            Center(
              child: category == 'Add Category'
                  ? Icon(icon, size: 50, color: color)
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 40, color: color),
                  const SizedBox(height: 5),
                  Text(
                    category,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(height: 0),
                  if (remainingBudget.isNotEmpty)
                    Text(
                      remainingBudget, // e.g. 'LE300.00'
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*class HollowCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final Random random = Random();
    for (int i = 0; i < 50; i++) {
      final double radius = 20 + i * 10;
      final double x = size.width * (i % 10) / 10;
      final double y = size.height * (i % 5) / 5;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}*/
