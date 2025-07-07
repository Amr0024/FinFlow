import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RecommendationsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final int themeIndex;

  const RecommendationsScreen({
    super.key,
    required this.categories,
    this.themeIndex = 0,
  });

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final List<Map<String, dynamic>> _recommendations = [
    {
      'title': 'Emergency Fund',
      'description': 'Build an emergency fund covering 3-6 months of expenses',
      'icon': Icons.savings,
      'color': Colors.green,
      'priority': 'High',
    },
    {
      'title': 'Budget Tracking',
      'description': 'Track your spending to identify areas for improvement',
      'icon': Icons.track_changes,
      'color': Colors.blue,
      'priority': 'High',
    },
    {
      'title': 'Debt Reduction',
      'description': 'Focus on paying off high-interest debt first',
      'icon': Icons.credit_card,
      'color': Colors.red,
      'priority': 'High',
    },
    {
      'title': 'Investment Planning',
      'description': 'Consider starting with index funds for long-term growth',
      'icon': Icons.trending_up,
      'color': Colors.orange,
      'priority': 'Medium',
    },
    {
      'title': 'Insurance Review',
      'description': 'Ensure you have adequate insurance coverage',
      'icon': Icons.security,
      'color': Colors.purple,
      'priority': 'Medium',
    },
    {
      'title': 'Retirement Planning',
      'description': 'Start planning for retirement early',
      'icon': Icons.work,
      'color': Colors.teal,
      'priority': 'Low',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.themes[widget.themeIndex];
    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.getPrimaryGradient(colorScheme),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.lightbulb, color: colorScheme.primary),
              SizedBox(width: 10),
              Text('Recommendations',
                  style: TextStyle(
                      color: colorScheme.onBackground,
                      fontWeight: FontWeight.bold,
                      fontSize: 22
                  )
              ),
            ],
          ),
          backgroundColor: colorScheme.background.withOpacity(0.95),
          iconTheme: IconThemeData(color: colorScheme.onBackground),
          elevation: 1,
        ),
        // No bottom navigation here - it's handled by the parent container
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
                      color: colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Financial Tips',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Personalized recommendations based on your spending patterns and financial goals',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Priority sections
              _buildPrioritySection('High Priority', Colors.red, colorScheme),
              SizedBox(height: 16),
              _buildPrioritySection('Medium Priority', Colors.orange, colorScheme),
              SizedBox(height: 16),
              _buildPrioritySection('Low Priority', Colors.green, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrioritySection(String title, Color priorityColor, ColorScheme colorScheme) {
    final filteredRecommendations = _recommendations
        .where((rec) => rec['priority'] == title.split(' ')[0])
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onBackground,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        ...filteredRecommendations.map((rec) => _buildRecommendationCard(rec, colorScheme)),
      ],
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation, ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: recommendation['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              recommendation['icon'],
              color: recommendation['color'],
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation['title'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  recommendation['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}