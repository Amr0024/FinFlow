import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/finflow_line_chart.dart';
import '../services/firestore_services.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/last_month_category_bar_chart.dart';

class ChartsScreen extends StatefulWidget {
  final int themeIndex;
  final List<Map<String, dynamic>> categories;
  
  const ChartsScreen({
    super.key,
    this.themeIndex = 0,
    this.categories = const [],
  });

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.themes[widget.themeIndex];
    
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.getPrimaryGradient(colorScheme),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.bar_chart, color: colorScheme.primary),
              SizedBox(width: 10),
              Text('Charts & Analytics', 
                style: TextStyle(
                  color: colorScheme.onBackground, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 22
                )
              ),
            ],
          ),
          backgroundColor: colorScheme.surface.withValues(alpha: 0.95),
          iconTheme: IconThemeData(color: colorScheme.onSurface),
          elevation: 1,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Analytics',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Visualize your spending patterns and financial trends',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              
              // Line Chart Section
              _buildChartSection(
                'Savings Trend',
                'Track your monthly savings over time',
                Icons.trending_up,
                colorScheme,
                _buildLineChart(colorScheme),
              ),
              SizedBox(height: 20),
              
              // Pie Chart Section
              _buildChartSection(
                'Category Breakdown',
                'See how your budget is distributed across categories',
                Icons.pie_chart,
                colorScheme,
                _buildPieChart(colorScheme),
              ),
              SizedBox(height: 20),
              
              // Bar Chart 1 Section
              _buildChartSection(
                'Last month category expanses',
                'See your expenses by category for last month',
                Icons.bar_chart,
                colorScheme,
                LastMonthCategoryBarChart(
                  categories: widget.categories,
                  theme: colorScheme,
                  height: 300,
                ),
              ),
              SizedBox(height: 20),
              
              // Bar Chart 2 Section
              _buildChartSection(
                'Priority vs Non-Priority',
                'Analyze your priority and non-priority expenses',
                Icons.compare_arrows,
                colorScheme,
                _buildBarChart2Placeholder(colorScheme),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection(String title, String description, IconData icon, ColorScheme colorScheme, Widget chart) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          chart,
        ],
      ),
    );
  }

  Widget _buildLineChart(ColorScheme colorScheme) {
    return FutureBuilder<List<Map<String, dynamic>>>(
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
        
        return Container(
          height: 250,
          child: FinFlowLineChart(
            savingsData: savingsData,
            monthLabels: monthLabels,
            theme: colorScheme,
          ),
        );
      },
    );
  }

  Widget _buildPieChart(ColorScheme colorScheme) {
    return CategoryPieChart(
      categories: widget.categories,
      theme: colorScheme,
      size: 250,
    );
  }

  Widget _buildBarChart2Placeholder(ColorScheme colorScheme) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.compare_arrows_outlined,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            SizedBox(height: 16),
            Text(
              'Priority Analysis Chart',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Priority vs non-priority expenses',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 