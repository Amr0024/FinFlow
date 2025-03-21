import 'package:flutter/material.dart';
import 'dart:math'; // Import for Random
import 'notes_screen.dart'; // Import the Notes Screen

class MainScreen extends StatefulWidget {
  final List<String> selectedGoals; // Selected financial goals
  final Map<String, dynamic> surveyResults; // Survey results

  MainScreen({required this.selectedGoals, required this.surveyResults}); // Constructor

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ScrollController _scrollController = ScrollController();
  double _bannerOpacity = 1.0; // Initial opacity of the banner
  double _bannerOffset = 0.0; // Initial offset of the banner
  final Random _random = Random();

  // Store category data (name, icon, color, budget)
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Groceries', 'icon': Icons.shopping_cart, 'color': Colors.green, 'budget': 0.0, 'expenses': []},
    {'name': 'Entertainment', 'icon': Icons.movie, 'color': Colors.purple, 'budget': 0.0, 'expenses': []},
    {'name': 'Bills', 'icon': Icons.receipt, 'color': Colors.blue, 'budget': 0.0, 'expenses': []},
    {'name': 'Add Category', 'icon': Icons.add, 'color': Colors.grey, 'budget': 0.0, 'expenses': []},
  ];

  // List of icons for the "Add Category" dialog
  final List<IconData> _availableIcons = [
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
  ];

  // Add this list to store recent transactions
  final List<Map<String, dynamic>> _recentTransactions = [];

  // Add variables for Total Balance and Monthly Budget
  double _totalBalance = 0.0; // Initial total balance
  double _monthlyBudget = 0.0; // Initial monthly budget

  // Variable to track the selected filter for recent transactions
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      // Adjust banner opacity and offset based on scroll position
      if (_scrollController.offset > 100) {
        _bannerOpacity = 0.0; // Fully fade out
        _bannerOffset = 100; // Stop moving after 100px
      } else {
        _bannerOpacity = 1.0 - (_scrollController.offset / 100); // Fade gradually
        _bannerOffset = _scrollController.offset; // Move banner with scroll
      }
    });
  }

  // Show a popup to set the Total Balance
  void _showSetTotalBalanceDialog() {
    TextEditingController _totalBalanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Total Balance'),
          content: TextField(
            controller: _totalBalanceController,
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
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_totalBalanceController.text.isNotEmpty) {
                  setState(() {
                    _totalBalance = double.parse(_totalBalanceController.text);
                    _monthlyBudget = _totalBalance; // Set Monthly Budget equal to Total Balance
                  });
                  Navigator.pop(context);
                }
              },
              child: Text('Set'),
            ),
          ],
        );
      },
    );
  }

  // Show a dialog to display the monthly plan
  void _showMonthlyPlanDialog() {
    Map<String, dynamic> monthlyPlan = _generateMonthlyPlan();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Your Monthly Plan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9, // Larger popup width
              height: MediaQuery.of(context).size.height * 0.7, // Larger popup height
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suggested Monthly Budget: \$${monthlyPlan['suggestedBudget'].toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Recommendations:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ...monthlyPlan['recommendations'].map((recommendation) {
                    return ListTile(
                      leading: Icon(Icons.lightbulb_outline, color: Colors.teal, size: 24),
                      title: Text(
                        recommendation,
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Close',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        );
      },
    );
  }

  // Generate a monthly plan based on survey results
  Map<String, dynamic> _generateMonthlyPlan() {
    // Extract survey data
    String trackingPreference = widget.surveyResults['How often do you want to track your expenses?'] ?? 'Monthly';
    String dailySpending = widget.surveyResults['On average, how much do you spend daily?'] ?? '\$20-\$50';
    String monthlySpending = widget.surveyResults['On average, how much do you spend monthly?'] ?? '\$500-\$1000';
    List<String> financialGoals = widget.surveyResults['Financial Goals'] ?? [];

    // Calculate suggested monthly budget
    double suggestedBudget = 0.0;
    if (monthlySpending == 'Less than \$500') {
      suggestedBudget = 400.0;
    } else if (monthlySpending == '\$500-\$1000') {
      suggestedBudget = 750.0;
    } else if (monthlySpending == '\$1000-\$2000') {
      suggestedBudget = 1500.0;
    } else if (monthlySpending == 'More than \$2000') {
      suggestedBudget = 2500.0;
    }

    // Add recommendations based on financial goals
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

  // Show a popup dialog to set or edit the budget for a category
  void _showBudgetDialog(int index) {
    TextEditingController _budgetController = TextEditingController(
      text: _categories[index]['budget'] == 0.0 ? '' : _categories[index]['budget'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Non-transparent background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8, // Larger popup width
            height: 200, // Taller popup height
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(_categories[index]['icon'], color: _categories[index]['color'], size: 30),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _budgetController,
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
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_budgetController.text.isNotEmpty) {
                      setState(() {
                        _categories[index]['budget'] = double.parse(_budgetController.text);
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Set Budget'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _categories[index]['color'],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show a dialog to add a new category
  void _showAddCategoryDialog() {
    TextEditingController _nameController = TextEditingController();
    IconData _selectedIcon = Icons.add;
    Color _selectedColor = Colors.grey;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add New Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Category Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text('Choose an Icon:', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: _availableIcons.map((icon) {
                      return IconButton(
                        icon: Icon(icon),
                        color: _selectedIcon == icon ? Colors.blue : Colors.grey,
                        onPressed: () {
                          setState(() {
                            _selectedIcon = icon;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  Text('Choose a Color:', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 10),
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
                            _selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedColor == color ? Colors.black : Colors.transparent,
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
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_nameController.text.isNotEmpty) {
                      setState(() {
                        _categories.insert(
                          _categories.length - 1,
                          {
                            'name': _nameController.text,
                            'icon': _selectedIcon,
                            'color': _selectedColor,
                            'budget': 0.0,
                            'expenses': [],
                          },
                        );
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Show a popup dialog to add expenses
  void _showAddExpensesDialog() {
    TextEditingController _amountController = TextEditingController();
    String _selectedCategory = _categories[0]['name']; // Default category
    String _trackingPreference = widget.surveyResults['How often do you want to track your expenses?'] ?? 'Monthly';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _trackingPreference == 'Daily' ? 'Enter Daily Expenses' : 'Enter Monthly Expenses',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                        items: _categories.map<DropdownMenuItem<String>>((category) {
                          return DropdownMenuItem<String>(
                            value: category['name'],
                            child: Row(
                              children: [
                                Icon(category['icon'], color: category['color']),
                                SizedBox(width: 10),
                                Text(category['name']),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    hintText: 'Enter Amount',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_amountController.text.isNotEmpty) {
                      setState(() {
                        double amount = double.parse(_amountController.text);

                        // Subtract from Monthly Budget
                        _monthlyBudget -= amount;

                        int categoryIndex = _categories.indexWhere((cat) => cat['name'] == _selectedCategory);

                        // Update the budget left for the category
                        if (_categories[categoryIndex]['budget'] > 0) {
                          _categories[categoryIndex]['budget'] -= amount;
                        }

                        // Add the expense to the category's expenses list
                        _categories[categoryIndex]['expenses'].add({
                          'amount': amount,
                          'isDaily': _trackingPreference == 'Daily',
                        });

                        // Add the transaction to the recent transactions list
                        _recentTransactions.add({
                          'category': _selectedCategory,
                          'amount': amount,
                          'icon': _categories[categoryIndex]['icon'],
                          'color': _categories[categoryIndex]['color'],
                        });

                        // Clear the input field
                        _amountController.clear();
                      });

                      Navigator.pop(context); // Close the dialog after adding the expense
                    }
                  },
                  child: Text('Add Expense'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Financial Goals Banner with Hollow Circles Texture
          Transform.translate(
            offset: Offset(0, -_bannerOffset), // Move banner up as user scrolls
            child: Opacity(
              opacity: _bannerOpacity,
              child: Container(
                height: 250, // Fixed height for the banner
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo[900]!, Colors.purple[800]!], // Dark blue to purple
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.2, 0.8], // Smooth transition
                    tileMode: TileMode.clamp, // Prevents weird lines
                  ),
                ),
                child: Stack(
                  children: [
                    // Hollow Circles Texture
                    CustomPaint(
                      size: Size(double.infinity, 230), // Match banner height
                      painter: HollowCirclePainter(),
                    ),
                    // Banner Content
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: 10), // Move FinFlow name down
                                child: Text(
                                  'FinFlow',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 10), // Move icons down
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.notifications, color: Colors.white),
                                      onPressed: () {
                                        // Handle notifications
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.settings, color: Colors.white),
                                      onPressed: () {
                                        // Navigate to settings
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Financial Goals',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10),
                          // Display selected goals
                          if (widget.selectedGoals.isNotEmpty)
                            ...widget.selectedGoals.map((goal) {
                              return _buildGoalProgress(goal, 50); // Default progress of 50%
                            }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Scrollable Content
          SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.only(top: 270), // Match banner height (240)
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview Section
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _showSetTotalBalanceDialog, // Open popup to set Total Balance
                        child: _buildOverviewCard('Total Balance', '\$${_totalBalance.toStringAsFixed(2)}', Colors.blue),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _buildOverviewCard('Monthly Budget Left', '\$${_monthlyBudget.toStringAsFixed(2)}', Colors.green),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                _buildOverviewCard('Last Month Savings Progress', '40%', Colors.orange),
                SizedBox(height: 20),

                // Quick Actions
                Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickActionButton(Icons.add, 'Add Expense', Colors.blue, _showAddExpensesDialog),
                    _buildQuickActionButton(Icons.attach_money, 'Add Income', Colors.green, () {}),
                    _buildQuickActionButton(Icons.calendar_today, 'Monthly Plan', Colors.teal, _showMonthlyPlanDialog),
                    _buildQuickActionButton(Icons.bar_chart, 'Reports', Colors.orange, () {
                      Navigator.pushNamed(context, '/reports'); // Navigate to Reports Screen
                    }),
                  ],
                ),
                SizedBox(height: 20),

                // Monthly Expenses Graph
                Text(
                  'Monthly Expenses Graph',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white, // Light gray background for the graph
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/graph_placeholder.png', // Replace with your graph image
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Expense Categories
                Text(
                  'Expense Categories',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 10.0, // Horizontal space between items
                  runSpacing: 20.0, // Vertical space between items
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
                        category['budget'] > 0 ? '\$${category['budget'].toStringAsFixed(2)}' : '',
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 40),

                // Recent Transactions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
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
                SizedBox(height: 10),
                Column(
                  children: _recentTransactions
                      .where((transaction) =>
                  _selectedFilter == 'All' || transaction['category'] == _selectedFilter)
                      .map((transaction) {
                    return _buildTransactionItem(
                      transaction['category'],
                      '-\$${transaction['amount'].toStringAsFixed(2)}',
                      transaction['icon'],
                      transaction['color'],
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
        currentIndex: 0, // Home is selected by default
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey, // Gray for deselected items
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => NotesScreen(categories: _categories),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0); // Start from the right
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;
                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);
                  return SlideTransition(position: offsetAnimation, child: child);
                },
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 10),
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
            radius: 40, // Increased size (2x larger)
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 40), // Increased icon size
          ),
          SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 16)), // Increased font size
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String category, String amount, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(category),
      trailing: Text(amount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildGoalProgress(String goal, int progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          goal,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(10), // Rounded corners
          child: LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple), // Purple progress bar
            minHeight: 10, // Thicker progress bar
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildCategoryBox(String category, IconData icon, Color color, String remainingBudget) {
    return Container(
      width: 140, // Increased width for the circle
      height: 140, // Increased height for the circle
      decoration: BoxDecoration(
        color: color.withOpacity(0.2), // Light background color
        shape: BoxShape.circle, // Circular shape
      ),
      child: ClipOval(
        child: Stack(
          children: [
            Center(
              child: category == 'Add Category'
                  ? Icon(
                icon,
                size: 50, // Increased icon size
                color: color, // Icon color
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 40, // Increased icon size
                    color: color, // Icon color
                  ),
                  SizedBox(height: 5),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 0),
                  if (remainingBudget.isNotEmpty) // Show remaining budget if available
                    Text(
                      remainingBudget,
                      style: TextStyle(
                        fontSize: 18, // Adjust font size for budget left
                        color: Colors.green, // Green color for remaining budget
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

// Custom painter for hollow circles (used in the banner)
class HollowCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.1) // Light white color for circles
      ..style = PaintingStyle.stroke // Hollow circles
      ..strokeWidth = 2; // Circle border width

    final Random random = Random();

    // Draw multiple circles
    for (int i = 0; i < 50; i++) {
      final double radius = 20 + i * 10; // Vary the radius
      final double x = size.width * (i % 10) / 10; // Spread horizontally
      final double y = size.height * (i % 5) / 5; // Spread vertically

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // No need to repaint
  }
}