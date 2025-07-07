// splash_screen.dart
import 'package:flutter/material.dart';
import 'package:projects_flutter/Screens/register_screen.dart';
import 'dart:async'; // Import for Timer
import 'login_screen.dart'; // Import the login screen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final List<String> tips = [
    "Stay on top of your finances with FinFlow.",
  ];

  int currentTipIndex = 0;
  late Timer _tipTimer; // Timer for cycling tips

  @override
  void initState() {
    super.initState();

    // Start a timer to cycle through tips every 2 seconds
    _tipTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          currentTipIndex = (currentTipIndex + 1) % tips.length;
        });
      }
    });

    // Navigate to the login screen after 10 seconds
    Future.delayed(Duration(seconds: 4), () {
      if (mounted) {
        _tipTimer.cancel(); // Stop the timer
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _tipTimer.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with gradient and hollow circles
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo[900]!, Colors.purple[800]!], // Dark blue to purple
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.2, 0.8], // Smooth transition
                tileMode: TileMode.clamp, // Prevents weird lines
              ),
            ),
            child: CustomPaint(
              size: Size.infinite
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/finflow_white.png',
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,    // or fill, cover, etc. as desired
                ),
                SizedBox(height: 20),
                Text(
                  'FinFlow', // App name
                  style: TextStyle(
                    fontFamily: 'Helvetica',
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 500), // Smooth transition
                    child: Text(
                      tips[currentTipIndex], // Display the current tip
                      key: ValueKey<int>(currentTipIndex), // Unique key for animation
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Helvetica',
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}