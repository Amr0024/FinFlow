import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RecommendationsScreen extends StatelessWidget {
  /// The list of categories passed down from the parent
  final List<Map<String, dynamic>> categories;

  /// Which theme index is currently selected
  final int themeIndex;

  /// Callback to notify the parent if the theme changes here
  final ValueChanged<int> onThemeUpdated;

  const RecommendationsScreen({
    Key? key,
    this.categories = const [],
    this.themeIndex = 0,
    required this.onThemeUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Grab the current ColorScheme based on the index
    final colors = AppTheme.themes[themeIndex];

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Recommendations'),
        backgroundColor: colors.primary,
        actions: [
          // Just as an example: allow the user to cycle the theme
          IconButton(
            icon: const Icon(Icons.palette),
            onPressed: () {
              // Toggle between theme 0 and 1 (modify as you like)
              final next = (themeIndex + 1) % AppTheme.themes.length;
              onThemeUpdated(next);
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final cat = categories[i];
          return Card(
            color: colors.secondaryContainer,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(cat['title'] ?? 'No title'),
              subtitle: Text(cat['description'] ?? ''),
              trailing: Text(
                cat['forecastValue']?.toStringAsFixed(2) ?? '--',
                style: TextStyle(color: colors.primary),
              ),
            ),
          );
        },
      ),
    );
  }
}