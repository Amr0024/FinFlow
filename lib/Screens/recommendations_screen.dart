import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/forecast_service.dart';
import '../services/fingpt_ai_service.dart';
import '../models/recommendation_model.dart';

class RecommendationsScreen extends StatelessWidget {
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
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.themes[widget.themeIndex];

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(child: Text('Error: \$_error'));
    } else {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._recs.map((r) => Card(
            color: colors.secondaryContainer,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(r.title),
              subtitle: Text(r.description),
              trailing: Text(
                r.forecastValue.toStringAsFixed(2),
                style: TextStyle(color: colors.primary),
              ),
            ),
          )),
          if (_tips.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('AI Tips', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ..._tips.map((t) => ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: Text('$t'),
            )),
          ],
        ],
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Recommendations'),
        backgroundColor: colors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.palette),
            onPressed: () {
              final next =
                  (widget.themeIndex + 1) % AppTheme.themes.length;
              widget.onThemeUpdated(next);
            },
          ),
        ],
      ),
      body: body,
    );
  }
}