//main.dart
import 'package:flutter/material.dart';
//import 'screens/main_screen.dart'; // Import the splash screen
import 'screens/splash_screen.dart'; // Import the splash screen
import 'screens/survey_screen.dart'; // Import the login screen
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinFlow',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(), // Start with the splash screen
    );
  }
}