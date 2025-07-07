import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class AccountDetailsPage extends StatefulWidget {

  const AccountDetailsPage({Key? key}) : super(key: key);


  @override
  State<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  String _firstName = '';
  String _lastName = '';
  String _username = '';
  String _email = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data() ?? <String, dynamic>{};
      setState(() {
        _firstName = data['firstName'] ?? '';
        _lastName = data['lastName'] ?? '';
        _username = data['username'] ?? '';
        _email = user.email ?? '';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.getPrimaryGradient(colorScheme),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Account Details', style: TextStyle(color: colorScheme.onBackground)),
          backgroundColor: colorScheme.background.withOpacity(0.95),
          iconTheme: IconThemeData(color: colorScheme.onBackground),
          elevation: 1,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ListTile(
              leading: Icon(Icons.person, color: colorScheme.primary),
              title: Text('Name', style: TextStyle(color: colorScheme.onSurface)),
              subtitle: Text('$_firstName $_lastName',
                  style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))),
            ),
            ListTile(
              leading: Icon(Icons.account_circle, color: colorScheme.primary),
              title: Text('Username',
                  style: TextStyle(color: colorScheme.onSurface)),
              subtitle: Text(_username,
                  style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))),
            ),
            ListTile(
              leading: Icon(Icons.email, color: colorScheme.primary),
              title: Text('Email', style: TextStyle(color: colorScheme.onSurface)),
              subtitle: Text(_email,
                  style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))),
            ),
          ],
        ),
      ),
    );
  }
}