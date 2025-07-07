import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

// Firebase core + services
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

// Local imports
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/survey_screen.dart';          // if you still use it
import 'screens/recommendations_screen.dart'; // make sure class is RecommendationsScreen

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

_connectToLocalEmulators();   // ← only when debugging

  runApp(const MyApp());
}

void _connectToLocalEmulators() {
  // Ports you exposed in docker-compose
  const firestorePort = 8080;
  const authPort      = 9099;
  const rtdbPort      = 9000;

  // Android emulators need 10.0.2.2 to reach the host; everything else can use localhost.
  final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';

  FirebaseFirestore.instance.useFirestoreEmulator(host, firestorePort);
  FirebaseFirestore.instance.settings = const Settings(
    sslEnabled: false,
    persistenceEnabled: false,
  );

  FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseDatabase.instance.useDatabaseEmulator(host, rtdbPort);

  debugPrint('🔌  Connected to local Firebase emulators at $host');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinFlow',
      theme: ThemeData(
        colorScheme: AppTheme.originalTheme,
        fontFamily: 'Helvetica',
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      // initialRoute lets you change the default screen easily
      initialRoute: '/',
      routes: {
        '/':       (context) => const SplashScreen(),
        '/survey': (context) => const SurveyScreen(),
        '/ai-recos': (context) => RecommendationsScreen(categories: [], themeIndex: 0, onThemeUpdated: (newIndex) {
          debugPrint('Theme change requested: $newIndex');
        }),
      },
    );
  }
}
