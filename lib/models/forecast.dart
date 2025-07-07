class Forecast {
  final DateTime generatedAt;
  final String uid;
  final Map<String, double> forecast;

  Forecast({
    required this.generatedAt,
    required this.uid,
    required this.forecast,
  });

  factory Forecast.fromJson(Map<String, dynamic> json) {
    // Parse the timestamp string:
    final genAt = DateTime.parse(json['generated_at'] as String);

    // Parse the nested map, converting num ➔ double:
    final rawForecast = json['forecast'] as Map<String, dynamic>;
    final Map<String, double> fc = rawForecast.map(
          (category, value) => MapEntry(category, (value as num).toDouble()),
    );

    return Forecast(
      generatedAt: genAt,
      uid: json['uid'] as String,
      forecast: fc,
    );
  }
}