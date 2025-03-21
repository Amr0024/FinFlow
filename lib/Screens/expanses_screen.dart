import 'package:flutter/material.dart';
import 'dart:math'; // For Random

class ExpansesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final Function(String category, double amount, bool isNotPriority, String? productName, String? mandatoryLevel) onExpenseAdded;

  ExpansesScreen({required this.categories, required this.onExpenseAdded});

  @override
  _ExpansesScreenState createState() => _ExpansesScreenState();
}

class _ExpansesScreenState extends State<ExpansesScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  String _selectedCategory = '';
  bool _isNotPriority = false;
  List<Map<String, dynamic>> _nonPriorityItems = [];
  String _mandatoryLevel = ''; // Low, Medium, High
  bool _showNonPriorityButton = false; // Controls visibility of "View Non-Priority Items" button

  @override
  void initState() {
    super.initState();
    // Set the default selected category to the first category in the list (excluding "Add Category")
    if (widget.categories.isNotEmpty) {
      _selectedCategory = widget.categories
          .where((category) => category['name'] != 'Add Category')
          .first['name'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Expense',
          style: TextStyle(fontSize: 24, color: Colors.white), // White text
        ),
        iconTheme: IconThemeData(color: Colors.white), // White arrow
        flexibleSpace: Container(
          height: 150, // Bigger banner
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo[900]!, Colors.purple[800]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.2, 0.8],
              tileMode: TileMode.clamp,
            ),
          ),
          child: CustomPaint(
            size: Size(double.infinity, 150), // Bigger banner
            painter: HollowCirclePainter(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enter Amount Box (always visible)
            Text(
              'Enter Amount',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
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

            // Category Section (visible before non-priority is selected)
            if (!_isNotPriority) ...[
              Text(
                'Select Category',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              DropdownButton<String>(
                value: _selectedCategory,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
                items: widget.categories
                    .where((category) => category['name'] != 'Add Category')
                    .map<DropdownMenuItem<String>>((category) {
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
              SizedBox(height: 20),
            ],

            // Non-Priority Checkbox
            CheckboxListTile(
              title: Text('Not a Priority Expense'),
              value: _isNotPriority,
              onChanged: (bool? value) {
                setState(() {
                  _isNotPriority = value!;
                  // Reset selected category when toggling non-priority
                  _selectedCategory = widget.categories
                      .where((category) => category['name'] != 'Add Category')
                      .first['name'];
                });
              },
            ),

            if (_isNotPriority) ...[
              // Product Name
              Text(
                'Product Name',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _productNameController,
                decoration: InputDecoration(
                  hintText: 'Enter Product Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // How Mandatory
              Text(
                'How Mandatory Was This Item?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _mandatoryLevel == 'Low',
                        onChanged: (bool? value) {
                          setState(() {
                            _mandatoryLevel = value! ? 'Low' : '';
                          });
                        },
                      ),
                      Text('Low'),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _mandatoryLevel == 'Medium',
                        onChanged: (bool? value) {
                          setState(() {
                            _mandatoryLevel = value! ? 'Medium' : '';
                          });
                        },
                      ),
                      Text('Medium'),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _mandatoryLevel == 'High',
                        onChanged: (bool? value) {
                          setState(() {
                            _mandatoryLevel = value! ? 'High' : '';
                          });
                        },
                      ),
                      Text('High'),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Category List (only for non-priority)
              Text(
                'Category (Optional)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              DropdownButton<String>(
                value: _selectedCategory,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
                items: [
                  ...widget.categories
                      .where((category) => category['name'] != 'Add Category')
                      .map<DropdownMenuItem<String>>((category) {
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
                  DropdownMenuItem(
                    value: 'None',
                    child: Text('None'),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],

            // Add Expense Button
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo[900]!, Colors.purple[800]!],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (_amountController.text.isEmpty || _selectedCategory.isEmpty) {
                    // Show error if amount or category is not selected
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please enter an amount and select a category.'),
                      ),
                    );
                    return;
                  }

                  if (_isNotPriority && _productNameController.text.isEmpty) {
                    // Show error if product name is not entered for non-priority expenses
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please enter a product name.'),
                      ),
                    );
                    return;
                  }

                  // Add expense
                  double amount = double.parse(_amountController.text);
                  widget.onExpenseAdded(
                    _selectedCategory,
                    amount,
                    _isNotPriority,
                    _isNotPriority ? _productNameController.text : null,
                    _isNotPriority ? _mandatoryLevel : null,
                  );

                  // If it's a non-priority expense, add it to the _nonPriorityItems list
                  if (_isNotPriority) {
                    setState(() {
                      _nonPriorityItems.add({
                        'name': _productNameController.text,
                        'amount': amount,
                        'category': _selectedCategory,
                        'mandatoryLevel': _mandatoryLevel,
                      });
                    });
                  }

                  // Reset all form fields (including non-priority checkbox)
                  setState(() {
                    _amountController.clear();
                    _productNameController.clear();
                    _mandatoryLevel = '';
                    _selectedCategory = widget.categories
                        .where((category) => category['name'] != 'Add Category')
                        .first['name']; // Reset to default category
                    _isNotPriority = false; // Reset non-priority checkbox
                    _showNonPriorityButton = true; // Show the "View Non-Priority Items" button
                  });

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Expense added successfully!'),
                    ),
                  );
                },
                child: Text(
                  'Add Expense',
                  style: TextStyle(color: Colors.white), // White text
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            // View Non-Priority Items Button
            if (_showNonPriorityButton) ...[
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo[900]!, Colors.purple[800]!],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // Show non-priority items in a dialog
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Non-Priority Items'),
                          content: SingleChildScrollView(
                            child: Column(
                              children: _nonPriorityItems.map((item) {
                                return ListTile(
                                  title: Text(item['name']),
                                  subtitle: Text(
                                    'Amount: \$${item['amount'].toStringAsFixed(2)}\n'
                                        'Category: ${item['category']}\n'
                                        'Mandatory: ${item['mandatoryLevel']}',
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text('Close'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text(
                    'View Non-Priority Items',
                    style: TextStyle(color: Colors.white), // White text
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
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
          if (index == 0) {
            Navigator.pop(context); // Go back to the home screen
          }
        },
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

    final Random random = Random(); // Initialize Random

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