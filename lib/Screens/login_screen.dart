import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projects_flutter/Screens/register_screen.dart';
import 'survey_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart'; // <-- For Google

import '../widgets/navigation_wrapper.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  LoginScreen({super.key});

  // ------------------------------------------------------
  // 1) Normal Email/Password login
  // ------------------------------------------------------
  void _login(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email and password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Sign in with Firebase Auth using email/password
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data() as Map<String, dynamic>;

          if (data['surveyResults'] != null) {
            final surveyResults = Map<String, dynamic>.from(data['surveyResults']);
            final selectedGoals = surveyResults['Financial Goals'] != null
                ? List<String>.from(surveyResults['Financial Goals'])
                : <String>[];

            // Navigate to NavigationWrapper
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => NavigationWrapper(
                  selectedGoals: selectedGoals,
                  surveyResults: surveyResults,
                ),
              ),
            );
          } else {
            // doc has no survey data => go to SurveyScreen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SurveyScreen()),
            );
          }
        } else {
          // doc doesn't exist => new user => go to Survey
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SurveyScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      print('Sign in error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign In Failed: ${e.message}')),
      );
    }
  }

  // ------------------------------------------------------
  // 2) Google Sign-In
  // -----------------------------------------------------
/*
  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // user canceled the sign-in
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with this credential
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        // Check if Firestore doc exists for this user
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data() as Map<String, dynamic>;
          if (data['surveyResults'] != null) {
            final surveyResults = Map<String, dynamic>.from(data['surveyResults']);
            final selectedGoals = surveyResults['Financial Goals'] != null
                ? List<String>.from(surveyResults['Financial Goals'])
                : <String>[];

            // Navigate to NavigationWrapper
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => NavigationWrapper(
                  selectedGoals: selectedGoals,
                  surveyResults: surveyResults,
                ),
              ),
            );
          } else {
            // no survey => go to Survey
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SurveyScreen()),
            );
          }
        } else {
          // doc doesn't exist => new user => go to Survey
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SurveyScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      print('Google sign-in error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In Failed: ${e.message}')),
      );
    } catch (e) {
      print('Other Google sign-in error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In Error: $e')),
      );
    }
  }
*/
  // ------------------------------------------------------
  // 3) Facebook Sign-In
  // ------------------------------------------------------
  /*Future<void> _signInWithFacebook(BuildContext context) async {
    try {
      // Trigger the sign-in flow
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        // get the access token
        final AccessToken accessToken = result.accessToken!;
        final credential = FacebookAuthProvider.credential(accessToken.token);

        // Sign in to Firebase
        final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        final user = userCredential.user;
        if (user != null) {
          // Check if Firestore doc exists for this user
          final docSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (docSnapshot.exists) {
            final data = docSnapshot.data() as Map<String, dynamic>;
            if (data['surveyResults'] != null) {
              final surveyResults = Map<String, dynamic>.from(data['surveyResults']);
              final selectedGoals = surveyResults['Financial Goals'] != null
                  ? List<String>.from(surveyResults['Financial Goals'])
                  : <String>[];

              // Navigate to NavigationWrapper
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => NavigationWrapper(
                    selectedGoals: selectedGoals,
                    surveyResults: surveyResults,
                  ),
                ),
              );
            } else {
              // doc has no survey => go to Survey
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SurveyScreen()),
              );
            }
          } else {
            // doc doesn't exist => new user => go to Survey
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SurveyScreen()),
            );
          }
        }
      } else if (result.status == LoginStatus.cancelled) {
        print('Facebook login cancelled by user.');
      } else {
        print('Facebook login failed: ${result.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Facebook Sign-In Failed: ${result.message}')),
        );
      }
    } on FirebaseAuthException catch (e) {
      print('Facebook sign-in error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Facebook Sign-In Failed: ${e.message}')),
      );
    } catch (e) {
      print('Other Facebook sign-in error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Facebook Sign-In Error: $e')),
      );
    }
  }
*/
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        children: [
          // gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo[900]!, Colors.purple[800]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.2, 0.8],
              ),
            ),
            // You can also add a painter here if you like
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Welcome back!',
                        style: TextStyle(
                          fontFamily: 'Helvetica-Bold',
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Glad to see you again!',
                        style: TextStyle(
                          fontFamily: 'Helvetica',
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 100),

                      // Email
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(fontFamily: 'Helvetica', color: Colors.white),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.mail, color: Colors.white),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          style: const TextStyle(fontFamily: 'Helvetica', color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(fontFamily: 'Helvetica', color: Colors.white),
                            border: InputBorder.none,
                            prefixIcon: Icon(CupertinoIcons.lock_fill, color: Colors.white),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          style: const TextStyle(fontFamily: 'Helvetica', color: Colors.white),
                        ),
                      ),

                      const SizedBox(height: 2),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () async {
                            final email = _emailController.text.trim();
                            if (email.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Enter your email to reset password'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } else {
                              try {
                                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Password reset link sent to $email'),
                                  ),
                                );
                              } on FirebaseAuthException catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontFamily: 'Helvetica-Bold',
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Normal Log In Button
                      ElevatedButton(
                        onPressed: () => _login(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Log In',
                            style: TextStyle(
                              fontFamily: 'Helvetica-Bold',
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // "Or continue with"
                      Text(
                        'Or continue with',
                        style: TextStyle(
                          fontFamily: 'Helvetica',
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Icons for Google & Facebook
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google
                          IconButton(
                            icon: const Icon(Icons.g_mobiledata, size: 70, color: Colors.white),
                            onPressed: () {},//=> _signInWithGoogle(context),
                            style: ButtonStyle(
                              overlayColor: MaterialStateProperty.resolveWith<Color?>((states){
                                if(states.contains(MaterialState.pressed)){
                                  return Colors.grey;
                                }
                                return null;
                              })
                            ),
                          ),

                          // Facebook
                          IconButton(
                            icon: const Icon(Icons.facebook, size: 40, color: Colors.white),
                            onPressed: () {
                              //_signInWithFacebook(context);
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 0),

                      // Register button
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(
                              fontFamily: 'Helvetica',
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            children: const [
                              TextSpan(
                                text: 'Register Now',
                                style: TextStyle(
                                  fontFamily: 'Helvetica-Bold',
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
