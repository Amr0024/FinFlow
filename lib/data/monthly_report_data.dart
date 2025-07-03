import 'package:flutter/material.dart';

/// This file contains all the data for your reports/charts.
/// You can freely edit the values below for testing purposes.
/// When you change these values, the app will reflect the changes automatically.
///
/// To update data from the app, use the provided methods.

class MonthlyReportData extends ChangeNotifier {
  // ──────────────────────────────── MONTHS DATA ────────────────────────────────
  /// List of months to display in charts (edit as needed)
  List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Total savings per month (index matches [months])
  /// EDIT these values to test different savings data
  List<double> totalSavings = [
    1200, 1800, 1500, 2200, 1900, 2500, 1500
    , 0, 0, 0, 0, 0
  ];

  /// Total expenses per month (index matches [months])
  /// EDIT these values to test different expenses data
  List<double> totalExpenses = [
    800, 1000, 900, 1200, 1100, 1300, 0, 0, 0, 0, 0, 0
  ];

  /// Monthly budget (index matches [months])
  /// EDIT these values to test different budget data
  List<double> monthlyBudget = [
    2000, 2000, 2000, 2500, 2500, 3000, 0, 0, 0, 0, 0, 0
  ];

  /// Budget left per month (index matches [months])
  /// EDIT these values to test different budget left data
  List<double> budgetLeft = [
    800, 1000, 1100, 1300, 1400, 1700, 0, 0, 0, 0, 0, 0
  ];

  // ──────────────────────────────── WEEKS DATA ────────────────────────────────
  /// List of weeks (for weekly charts)
  List<String> weeks = [
    'Week 1', 'Week 2', 'Week 3', 'Week 4'
  ];

  /// Savings per week (edit as needed)
  List<double> weeklySavings = [300, 450, 380, 520];

  /// Expenses per week (edit as needed)
  List<double> weeklyExpenses = [200, 300, 250, 350];

  // ──────────────────────────────── CATEGORY DATA ─────────────────────────────
  /// Pie chart data: category name and percentage (edit as needed)
  List<CategoryData> categories = [
    CategoryData('Category 1', 40),
    CategoryData('Category 2', 30),
    CategoryData('Category 3', 30),
  ];

  // ──────────────────────────────── DAYS LEFT ────────────────────────────────
  /// Days left in the current month (edit for testing)
  int daysLeft = 30;

  // ──────────────────────────────── UPDATE METHODS ────────────────────────────
  /// Call this method after changing any value programmatically to update the UI
  void update() {
    notifyListeners();
  }

  // Example: update savings for a month
  void setMonthlySavings(int monthIndex, double value) {
    if (monthIndex >= 0 && monthIndex < totalSavings.length) {
      totalSavings[monthIndex] = value;
      notifyListeners();
    }
  }

  // Example: update days left
  void setDaysLeft(int value) {
    daysLeft = value;
    notifyListeners();
  }
}

class CategoryData {
  final String name;
  final double percent; // e.g., 40 for 40%
  CategoryData(this.name, this.percent);
} 