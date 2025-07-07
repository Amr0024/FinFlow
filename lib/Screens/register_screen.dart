import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'survey_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:projects_flutter/services/firestore_services.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  // Controllers for user input
  static final TextEditingController _firstNameController = TextEditingController();
  static final TextEditingController _lastNameController = TextEditingController();
  static final TextEditingController _usernameController = TextEditingController();
  static final TextEditingController _emailController = TextEditingController();
  static final TextEditingController _passwordController = TextEditingController();

  // -----------------------------------
  // Password complexity check
  // -----------------------------------
  bool _isPasswordValid(String password) {
    final minLength = 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasDigits = RegExp(r'[0-9]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasSpecialCharacters = RegExp(r'[!@#\$&*~]').hasMatch(password);

    return password.length >= minLength &&
        hasUppercase &&
        hasDigits &&
        hasLowercase;
  }

  // Main registration method
  Future<void> _register(BuildContext context) async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final userName = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Basic empty checks
    if (firstName.isEmpty ||
        lastName.isEmpty ||
        userName.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // -------------------------------------
    // Enforce stronger password rules
    // -------------------------------------
    if (!_isPasswordValid(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password must be at least 8 chars, include upper/lowercase, a digit, and a special character.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // ---------- 1)  create auth user ----------
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await FirestoreService.initNewUser(
        firstName: firstName,
        lastName : lastName,
        email    : email,
      );

      final uid = cred.user!.uid;

      // ---------- 2)  base profile doc ----------
      try{
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'firstName' : firstName,
          'lastName'  : lastName,
          'username'  : userName,
          'email'     : email,
          'createdAt' : FieldValue.serverTimestamp(),
        }); debugPrint('✅ Firestore write succeeded');
      } catch (e, stack) {
        debugPrint('Firestore write failed $e\n$stack');
      }

      // ---------- 3)  initialise balance ----------
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('balance')
          .doc('current')
          .set({'total': 0.0, 'monthlyBudget': 0.0});

      // (optional) ---------- 4)  add a few starter categories ----------
      await FirestoreService.addCategory(
        name : 'Groceries',
        color: Colors.green.value,
        icon : Icons.shopping_cart.codePoint,
      );
      await FirestoreService.addCategory(
        name : 'Bills',
        color: Colors.blue.value,
        icon : Icons.receipt.codePoint,
      );
      await FirestoreService.addCategory(
        name : 'Entertainment',
        color: Colors.purple.value,
        icon : Icons.movie.codePoint,
      );

      // ---------- 5)  go to Survey  ----------
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SurveyScreen()),
      );

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration Failed: ${e.message}'), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e'), backgroundColor: Colors.red),
      );
    }
    on FirebaseAuthException catch (e) {
      // Display any errors (e.g., email already in use, invalid format, etc.)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration Failed: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // Catch-all for other exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top bar
      backgroundColor: Colors.teal,
      appBar: AppBar(
          title: Text('Sign Up',
            style: TextStyle(
              fontFamily: 'Helvetica-Bold',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
      ),),
      body: Stack(
        children: [
          // Gradient background with hollow circles
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo[900]!, Colors.purple[800]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.2, 0.8],
              ),
            ),
            child: CustomPaint(
              size: Size.infinite
            ),
          ),
          // Main content
          SafeArea(
            minimum: const EdgeInsets.only(top: 0, bottom: 20),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 0, left: 20, right: 20.0, bottom: 80),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Create a New Account',
                        style: TextStyle(
                          fontFamily: 'Helvetica-Bold',
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'We\'re excited to have you on board!',
                        style: TextStyle(
                          fontFamily: 'Helvetica',
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // First Name
                      _buildTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                        icon: CupertinoIcons.person_fill,
                      ),
                      const SizedBox(height: 20),

                      // Last Name
                      _buildTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        icon: CupertinoIcons.person_fill,
                      ),
                      const SizedBox(height: 20),

                      // Username
                      _buildTextField(
                        controller: _usernameController,
                        label: 'Username',
                        icon: CupertinoIcons.profile_circled,
                      ),
                      const SizedBox(height: 20),

                      // Email Address
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),

                      // Password
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: CupertinoIcons.lock_fill,
                        isPassword: true,
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: () => _register(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              fontFamily: 'Helvetica',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Link back to login (optional)
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // or push to a LoginScreen
                        },
                        child: RichText(
                          text: TextSpan(
                            text: "Already have an account? ",
                            style: TextStyle(fontFamily: 'Helvetica',fontSize: 16 , color: Colors.white.withOpacity(0.8)),
                            children: const [
                              TextSpan(
                                text: 'Login',
                                style: TextStyle(
                                  fontFamily: 'Helvetica',
                                  fontSize: 18,
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

  // Reusable method to build text fields with the same style
  static Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(fontFamily: 'Helvetica', color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontFamily: 'Helvetica' ,color: Colors.white),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.white),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// Painter for the gradient background circles
/*class HollowCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 50; i++) {
      final double radius = 20 + i * 10;
      final double x = size.width * (i % 10) / 10;
      final double y = size.height * (i % 5) / 5;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}*/
