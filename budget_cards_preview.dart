import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() => runApp(BudgetCardsPreviewApp());

class BudgetCardsPreviewApp extends StatefulWidget {
  @override
  State<BudgetCardsPreviewApp> createState() => _BudgetCardsPreviewAppState();
}

class _BudgetCardsPreviewAppState extends State<BudgetCardsPreviewApp>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Sample data
  double totalBudget = 5000.0;
  double budgetLeft = 3200.0;
  double monthlySpending = 1800.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF5B86E5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Helvetica',
      ),
      home: Scaffold(
        backgroundColor: Color(0xFFF6F8FC),
        appBar: AppBar(
          title: Text(
            'Budget Cards Design Preview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Color(0xFF5B86E5),
          elevation: 0,
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Improved Budget Overview Cards',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Modern design with better visual hierarchy and animations',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF718096),
                    ),
                  ),
                  SizedBox(height: 32),
                  
                  // Row 1: Total Budget and Budget Left
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernBudgetCard(
                          title: 'Total Monthly Budget',
                          value: '${totalBudget.toStringAsFixed(0)} LE',
                          subtitle: 'Your monthly budget target',
                          icon: Icons.account_balance_wallet,
                          primaryColor: Color(0xFF5B86E5),
                          secondaryColor: Color(0xFF36D1DC),
                          progress: 1.0,
                          isPositive: true,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildModernBudgetCard(
                          title: 'Monthly Budget Left',
                          value: '${budgetLeft.toStringAsFixed(0)} LE',
                          subtitle: 'Remaining budget this month',
                          icon: Icons.savings,
                          primaryColor: Color(0xFF4CAF50),
                          secondaryColor: Color(0xFF81C784),
                          progress: budgetLeft / totalBudget,
                          isPositive: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  
                  // Row 2: Monthly Spending (Full width)
                  _buildModernBudgetCard(
                    title: 'Monthly Spending',
                    value: '${monthlySpending.toStringAsFixed(0)} LE',
                    subtitle: 'Total spent this month',
                    icon: Icons.trending_down,
                    primaryColor: Color(0xFFFF6B6B),
                    secondaryColor: Color(0xFFFF8E8E),
                    progress: monthlySpending / totalBudget,
                    isPositive: false,
                    isFullWidth: true,
                  ),
                  
                  SizedBox(height: 40),
                  
                  // Alternative Design Section
                  Text(
                    'Alternative Card Designs',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Minimalist Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildMinimalistCard(
                          title: 'Total Budget',
                          value: '${totalBudget.toStringAsFixed(0)} LE',
                          color: Color(0xFF5B86E5),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildMinimalistCard(
                          title: 'Budget Left',
                          value: '${budgetLeft.toStringAsFixed(0)} LE',
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildMinimalistCard(
                          title: 'Spending',
                          value: '${monthlySpending.toStringAsFixed(0)} LE',
                          color: Color(0xFFFF6B6B),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Glassmorphic Cards
                  _buildGlassmorphicCard(
                    title: 'Monthly Spending',
                    value: '${monthlySpending.toStringAsFixed(0)} LE',
                    subtitle: '${((monthlySpending / totalBudget) * 100).toStringAsFixed(1)}% of total budget',
                    icon: Icons.pie_chart,
                    color: Color(0xFFFF6B6B),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernBudgetCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color primaryColor,
    required Color secondaryColor,
    required double progress,
    required bool isPositive,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.1),
            secondaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositive ? Color(0xFF4CAF50).withOpacity(0.1) : Color(0xFFFF6B6B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: isPositive ? Color(0xFF4CAF50) : Color(0xFFFF6B6B),
                    size: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: primaryColor.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      minHeight: 8,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalistCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF718096),
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphicCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF718096),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
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