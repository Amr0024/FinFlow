import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recommendation_model.dart';

class ForecastService {
  /// Set [connectToEmulator]=false in production.
  factory ForecastService({bool connectToEmulator = true}) {
    final db = FirebaseFirestore.instance;

    if (connectToEmulator) {
      const int port = 8080;              // ← the port you exposed in docker-compose
      db.useFirestoreEmulator(_host(), port);
      db.settings = const Settings(
        persistenceEnabled: false,
        sslEnabled: false,
      );
    }

    return ForecastService._(db);
  }

  ForecastService._(this._db);
  final FirebaseFirestore _db;

  /// Pull every forecast document for this user.
  Future<List<RecommendationModel>> fetchRecommendations(String uid) async {
    final qs = await _db
        .collection('ai-forecast')
        .doc(uid)
        .collection('forecasts')          // adjust if you changed the name
        .get();

    return qs.docs
        .map((d) => RecommendationModel.fromMap(d.data()))
        .toList();
  }

  /// 10.0.2.2 for Android emulators, localhost everywhere else
  static String _host() {
    if (Platform.isAndroid) return '10.0.2.2';
    if (Platform.isIOS)     return '127.0.0.1';
    return 'localhost';     // macOS, Windows, Linux, Web
  }
}
