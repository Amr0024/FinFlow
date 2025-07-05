import 'package:firebase_core/firebase_core.dart';
import 'package:projects_flutter/services/firestore_services.dart';
import 'package:projects_flutter/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Prompt for email and password (or use hardcoded credentials for admin)
  // For safety, you may want to use a test account or your own admin account
  final email = 'YOUR_EMAIL_HERE';
  final password = 'YOUR_PASSWORD_HERE';
  await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);

  print('Running transaction fix for user: ' + FirebaseAuth.instance.currentUser!.uid);
  await FirestoreService.fixExistingTransactionData();
  print('Existing transaction data fixed.');
} 