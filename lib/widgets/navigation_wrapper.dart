import 'package:flutter/material.dart';
import '../Screens/main_screen.dart';
import '../Screens/notes_screen.dart';
import '../Screens/financial_goals_screen.dart';
import '../Screens/recommendations_screen.dart';
import '../theme/app_theme.dart';

class NavigationWrapper extends StatefulWidget {
  final List<String> selectedGoals;
  final Map<String, dynamic> surveyResults;

  const NavigationWrapper({
    super.key,
    required this.selectedGoals,
    required this.surveyResults,
  });

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  int _currentIndex = 0;
  int _selectedThemeIndex = 0;
  List<Map<String, dynamic>> _categories = [];
  
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      
      // Animate to the new page
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _updateCategories(List<Map<String, dynamic>> categories) {
    setState(() {
      _categories = categories;
    });
  }

  void _updateTheme(int themeIndex) {
    setState(() {
      _selectedThemeIndex = themeIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = AppTheme.themes[_selectedThemeIndex];
    
    return Scaffold(
      backgroundColor: currentTheme.brightness == Brightness.dark
          ? Color(0xFF1A202C)
          : Color(0xFFE0E5EC),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          // Home Screen
          MainScreen(
            selectedGoals: widget.selectedGoals,
            surveyResults: widget.surveyResults,
          ),
          
          // Notes Screen
          NotesScreen(
            categories: _categories,
          ),
          
          // Goals Screen
          FinancialGoalsScreen(
            colorScheme: currentTheme,
          ),
          
          // Recommendations Screen
          RecommendationsScreen(
            categories: _categories,
            themeIndex: _selectedThemeIndex,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: currentTheme.primary,
        unselectedItemColor: currentTheme.onBackground.withOpacity(0.5),
        backgroundColor: currentTheme.surface,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.notes), label: 'Notes'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Goals'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: 'AI Tips'),
        ],
        onTap: _onTabChanged,
      ),
    );
  }
} 