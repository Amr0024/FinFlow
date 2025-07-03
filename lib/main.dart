//main.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
//import 'screens/main_screen.dart'; // Import the splash screen
import 'screens/splash_screen.dart'; // Import the splash screen
import 'screens/survey_screen.dart'; // Import the login screen
import 'theme/app_theme.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
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
      home: SplashScreen(), // Start with the splash screen
      debugShowCheckedModeBanner: false,
    );
  }
}