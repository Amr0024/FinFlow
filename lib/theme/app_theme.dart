import 'package:flutter/material.dart';

class AppTheme {
  // Default Theme: Blue & Purple Gradient (like sunset, but blue/purple)
  static const ColorScheme originalTheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF5B86E5),      // Blue
    onPrimary: Colors.white,
    secondary: Color(0xFF8F6ED5),    // Purple
    onSecondary: Colors.white,
    tertiary: Color(0xFF6A1B9A),     // Deep Purple
    onTertiary: Colors.white,
    error: Color(0xFFEF4444),
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Color(0xFF1E293B),
    background: Color(0xFFF6F8FC),
    onBackground: Color(0xFF1E293B),
    outline: Color(0xFFE2E8F0),
    outlineVariant: Color(0xFFCBD5E1),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF1E293B),
    onInverseSurface: Colors.white,
    inversePrimary: Color(0xFF7C3AED),
    surfaceTint: Color(0xFF5B86E5),
  );

  // Dark Mode Theme: Black with subtle gray lines, cards are dark gray
  static const ColorScheme darkTheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF18191A),      // Black
    onPrimary: Colors.white,
    secondary: Color(0xFF232526),    // Dark Gray
    onSecondary: Colors.white,
    tertiary: Color(0xFF444444),     // Subtle Gray
    onTertiary: Colors.white,
    error: Color(0xFFEF4444),
    onError: Colors.white,
    surface: Color(0xFF232526),      // Card color: dark gray
    onSurface: Colors.white,
    background: Color(0xFF18191A),   // Main background: black
    onBackground: Colors.white,
    outline: Color(0xFF444444),      // Subtle gray lines
    outlineVariant: Color(0xFF232526),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Colors.white,
    onInverseSurface: Color(0xFF18191A),
    inversePrimary: Color(0xFF8F6ED5),
    surfaceTint: Color(0xFF232526),
  );

  // Ocean Blue Theme
  static const ColorScheme oceanBlue = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF1E3A8A),      // Deep blue
    onPrimary: Colors.white,
    secondary: Color(0xFF0EA5E9),    // Sky blue
    onSecondary: Colors.white,
    tertiary: Color(0xFF06B6D4),     // Cyan
    onTertiary: Colors.white,
    error: Color(0xFFEF4444),
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Color(0xFF1E293B),
    background: Color(0xFFF8FAFC),   // Light gray
    onBackground: Color(0xFF1E293B),
    outline: Color(0xFFE2E8F0),
    outlineVariant: Color(0xFFCBD5E1),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF1E293B),
    onInverseSurface: Colors.white,
    inversePrimary: Color(0xFF3B82F6),
    surfaceTint: Color(0xFF1E3A8A),
  );

  // Emerald Green Theme
  static const ColorScheme emeraldGreen = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF059669),      // Emerald
    onPrimary: Colors.white,
    secondary: Color(0xFF10B981),    // Green
    onSecondary: Colors.white,
    tertiary: Color(0xFF34D399),     // Light green
    onTertiary: Colors.white,
    error: Color(0xFFEF4444),
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Color(0xFF064E3B),
    background: Color(0xFFF0FDF4),   // Light green bg
    onBackground: Color(0xFF064E3B),
    outline: Color(0xFFD1FAE5),
    outlineVariant: Color(0xFFA7F3D0),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF064E3B),
    onInverseSurface: Colors.white,
    inversePrimary: Color(0xFF10B981),
    surfaceTint: Color(0xFF059669),
  );

  // Sunset Purple Theme (as provided)
  static const ColorScheme sunsetPurple = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF7C3AED),
    onPrimary: Colors.white,
    secondary: Color(0xFFF59E0B),
    onSecondary: Colors.white,
    tertiary: Color(0xFFEC4899),
    onTertiary: Colors.white,
    error: Color(0xFFEF4444),
    onError: Colors.white,
    background: Color(0xFFFDF2F8),
    onBackground: Color(0xFF581C87),
    surface: Colors.white,
    onSurface: Color(0xFF581C87),
  );

  // Theme List for Selection
  static const List<ColorScheme> themes = [
    originalTheme,
    darkTheme,
    oceanBlue,
    emeraldGreen,
    sunsetPurple,
  ];

  static const List<String> themeNames = [
    'Original',
    'Dark Mode',
    'Ocean Blue',
    'Emerald Green',
    'Sunset Purple',
  ];

  // Dynamic Gradients based on current theme
  static LinearGradient getPrimaryGradient(ColorScheme theme) {
    // Default theme: blue-purple gradient (subtle, like original sunset)
    if (theme == originalTheme) {
      return LinearGradient(
        colors: [Color(0xFF5B86E5), Color(0xFF8F6ED5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    // Dark theme: black to dark gray gradient
    if (theme == darkTheme) {
      return LinearGradient(
        colors: [Color(0xFF18191A), Color(0xFF232526)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    // Sunset theme: original sunset gradient
    if (theme == sunsetPurple) {
      return LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFFF59E0B), Color(0xFFEC4899)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    // Fallback
    return LinearGradient(
      colors: [theme.primary, theme.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient getSuccessGradient(ColorScheme theme) {
    return LinearGradient(
      colors: [Colors.green[600]!, Colors.green[400]!],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient getWarningGradient(ColorScheme theme) {
    return LinearGradient(
      colors: [Colors.orange[600]!, Colors.orange[400]!],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // Dynamic Decorations based on current theme - Improved to look more appealing
  static BoxDecoration getGlassCardDecoration(ColorScheme theme) {
    return BoxDecoration(
      color: theme.brightness == Brightness.dark
          ? Colors.white.withOpacity(0.15)
          : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(0.2)
            : theme.primary.withOpacity(0.1),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: theme.primary.withOpacity(0.15),
          blurRadius: 15,
          offset: const Offset(0, 8),
          spreadRadius: 2,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration getGradientCardDecoration(ColorScheme theme) {
    return BoxDecoration(
      gradient: getPrimaryGradient(theme),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: theme.primary.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 10),
          spreadRadius: 2,
        ),
      ],
    );
  }

  // Dynamic Text Styles based on current theme
  static TextStyle getHeadingStyle(ColorScheme theme) {
    return TextStyle(
      fontFamily: 'Helvetica-Bold',
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: theme.onBackground,
    );
  }

  static TextStyle getSubheadingStyle(ColorScheme theme) {
    return TextStyle(
      fontFamily: 'Helvetica',
      fontSize: 18,
      color: theme.onBackground,
    );
  }

  static TextStyle getBodyStyle(ColorScheme theme) {
    return TextStyle(
      fontFamily: 'Helvetica',
      fontSize: 16,
      color: theme.onBackground,
    );
  }

  // Chart Colors for different themes
  static List<Color> getChartColors(ColorScheme theme) {
    switch (theme) {
      case originalTheme:
        return [
          const Color(0xFF6A1B9A), // Purple
          const Color(0xFF8E24AA), // Purple
          const Color(0xFF9C27B0), // Purple
          const Color(0xFFAB47BC), // Purple
        ];
      case darkTheme:
        return [
          const Color(0xFF6A1B9A), // Dark Purple
          const Color(0xFF1565C0), // Dark Blue
          const Color(0xFF8E24AA), // Dark Purple
          const Color(0xFFAB47BC), // Purple
        ];
      case oceanBlue:
        return [
          const Color(0xFF1E3A8A), // Deep Blue
          const Color(0xFF0EA5E9), // Sky Blue
          const Color(0xFF06B6D4), // Cyan
          const Color(0xFF0891B2), // Blue
        ];
      case emeraldGreen:
        return [
          const Color(0xFF059669), // Emerald
          const Color(0xFF10B981), // Green
          const Color(0xFF34D399), // Light Green
          const Color(0xFF6EE7B7), // Green
        ];
      case sunsetPurple:
        return [
          const Color(0xFF7C3AED), // Purple
          const Color(0xFFF59E0B), // Amber
          const Color(0xFFEC4899), // Pink
          const Color(0xFFF97316), // Orange
        ];
      default:
        return [
          const Color(0xFF6A1B9A),
          const Color(0xFF8E24AA),
          const Color(0xFF9C27B0),
          const Color(0xFFAB47BC),
        ];
    }
  }

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration slowAnimation = Duration(milliseconds: 800);

  // Border Radius
  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(8));
  static const BorderRadius mediumRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(24));

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}