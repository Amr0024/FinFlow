import 'package:flutter/material.dart';
import '../Screens/notes_screen.dart';
import '../Screens/financial_goals_screen.dart';
import '../Screens/recommendations_screen.dart';
import '../theme/app_theme.dart';

class SharedBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ColorScheme theme;
  final List<Map<String, dynamic>> categories;
  final int themeIndex;
  final Function(int) onTabChanged;

  const SharedBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.theme,
    required this.categories,
    this.themeIndex = 0,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: theme.primary,
      unselectedItemColor: theme.onBackground.withOpacity(0.5),
      backgroundColor: theme.surface,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.notes), label: 'Notes'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Goals'),
        BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: 'Tips'),
      ],
      onTap: onTabChanged,
    );
  }
} 