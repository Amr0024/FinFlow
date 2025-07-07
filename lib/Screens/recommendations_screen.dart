import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/forecast_service.dart';
import '../services/fingpt_ai_service.dart';
import '../models/recommendation_model.dart';

class RecommendationsScreen extends StatefulWidget {
  final int themeIndex;
  final ValueChanged<int> onThemeUpdated;

  const RecommendationsScreen({
    Key? key,
    this.themeIndex = 0,
    required this.onThemeUpdated,
  }) : super(key: key);

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}
class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final _forecastService = ForecastService();
  final _finGptService = FinGPTApiService();

  List<RecommendationModel> _recs = [];
  List<dynamic> _tips = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final recs = await _forecastService.fetchRecommendations(uid);
      final tips = await _finGptService.getRecommendations();
      setState(() {
        _recs = recs;
        _tips = tips;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Recommendation load error: $e');
      setState(() {
        _error = 'Failed to load recommendations';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = AppTheme.themes[widget.themeIndex];

    Widget content;
    if (_loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = Center(
        child: Text('Error: \$_error', style: AppTheme.getBodyStyle(scheme)),
      );
    } else {
      content = ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_recs.isNotEmpty) ...[
            Text('Forecast Recommendations',
                style: AppTheme.getHeadingStyle(scheme).copyWith(fontSize: 24)),
            const SizedBox(height: 12),
            ..._recs.map((r) => Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.getGlassCardDecoration(scheme),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title,
                      style: AppTheme
                          .getSubheadingStyle(scheme)
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(r.description, style: AppTheme.getBodyStyle(scheme)),
                  const SizedBox(height: 8),
                  Text(r.forecastValue.toStringAsFixed(2),
                      style: AppTheme
                          .getHeadingStyle(scheme)
                          .copyWith(fontSize: 20, color: scheme.primary)),
                ],
              ),
            )),
          ],
          if (_tips.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('FinGPT Tips',
                style: AppTheme.getHeadingStyle(scheme).copyWith(fontSize: 24)),
            const SizedBox(height: 12),
            ..._tips.map((t) => Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.getGlassCardDecoration(scheme),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, color: scheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('$t', style: AppTheme.getBodyStyle(scheme)),
                  ),
                ],
              ),
            )),
          ],
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.getPrimaryGradient(scheme)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('AI Recommendations',
              style: TextStyle(color: scheme.onBackground)),
          backgroundColor: scheme.background.withOpacity(0.9),
          iconTheme: IconThemeData(color: scheme.onBackground),
          actions: [
            IconButton(
              icon: const Icon(Icons.palette),
              onPressed: () {
                final next = (widget.themeIndex + 1) % AppTheme.themes.length;
                widget.onThemeUpdated(next);
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: content,
        ),
      ),
    );
  }
}