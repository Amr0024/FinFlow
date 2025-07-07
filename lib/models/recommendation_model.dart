// lib/models/recommendation_model.dart

class RecommendationModel {
  final String title;
  final String description;
  final String category;        // e.g. “Groceries”
  final double forecastValue;   // AI forecast for this category

  const RecommendationModel({
    required this.title,
    required this.description,
    required this.category,
    required this.forecastValue,
  });

  factory RecommendationModel.fromMap(Map<String, dynamic> m) {
    return RecommendationModel(
      title:         m['title']       as String,
      description:   m['description'] as String,
      category:      m['category']    as String,
      forecastValue: (m['forecast']   as num).toDouble(),
    );
  }
}
