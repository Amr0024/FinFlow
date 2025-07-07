import 'package:flutter/material.dart';
import '../Screens/main_screen.dart';
import '../Screens/notes_screen.dart';
import '../Screens/financial_goals_screen.dart';
import '../Screens/recommendations_screen.dart';
import '../widgets/shared_bottom_navigation.dart';
import '../theme/app_theme.dart';

class MainContainer extends StatefulWidget {
  final List<String> selectedGoals;
  final Map<String, dynamic> surveyResults;

  const MainContainer({
    super.key,
    required this.selectedGoals,
    required this.surveyResults,
  });

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _selectedThemeIndex = 0;
  List<Map<String, dynamic>> _categories = [];

  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
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
            onCategoriesUpdated: _updateCategories,
            onThemeUpdated: _updateTheme,
            themeIndex: _selectedThemeIndex,
          ),

          // Notes Screen
          NotesScreen(
            categories: _categories,
            themeIndex: _selectedThemeIndex,
            onThemeUpdated: _updateTheme,
          ),

          // Goals Screen
          FinancialGoalsScreen(
            colorScheme: currentTheme,
            themeIndex: _selectedThemeIndex,
            onThemeUpdated: _updateTheme,
          ),

          // Recommendations Screen
          RecommendationsScreen(
            categories: _categories,
            themeIndex: _selectedThemeIndex,
          ),
        ],
      ),
      bottomNavigationBar: SharedBottomNavigation(
        currentIndex: _currentIndex,
        theme: currentTheme,
        onTabChanged: _onTabChanged,
        categories: _categories,
      ),
    );
  }
} 