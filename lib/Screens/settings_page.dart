 import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  final int currentThemeIndex;
  final ValueChanged<int> onThemeChanged;
  const SettingsPage({Key? key, required this.currentThemeIndex, required this.onThemeChanged}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _name = '';
  String _email = '';
  bool _loading = true;
  late int _selectedThemeIndex;

  @override
  void initState() {
    super.initState();
    _selectedThemeIndex = widget.currentThemeIndex;
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _name = (doc.data()?['firstName'] ?? '') + ' ' + (doc.data()?['lastName'] ?? '');
        _email = user.email ?? '';
        _loading = false;
      });
    }
  }

  void _onThemeChanged(int i) {
    setState(() => _selectedThemeIndex = i);
    widget.onThemeChanged(i);
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
          title: Row(
            children: [
              Icon(Icons.settings, color: colorScheme.primary),
              SizedBox(width: 10),
              Text('Settings', style: TextStyle(color: colorScheme.onBackground, fontWeight: FontWeight.bold, fontSize: 22)),
            ],
          ),
          backgroundColor: colorScheme.background.withOpacity(0.95),
          iconTheme: IconThemeData(color: colorScheme.onBackground),
          elevation: 1,
        ),
        body: _loading
            ? Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.all(20),
                children: [
                  // Connected card group
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.07),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Profile section (top rounded)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 44,
                                backgroundColor: colorScheme.primary.withOpacity(0.13),
                                child: Icon(Icons.person, size: 54, color: colorScheme.primary),
                              ),
                              SizedBox(height: 16),
                              Text(_name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: colorScheme.onBackground)),
                              SizedBox(height: 6),
                              Text(_email, style: TextStyle(color: colorScheme.onBackground.withOpacity(0.7), fontSize: 16)),
                            ],
                          ),
                        ),
                        Divider(height: 0, thickness: 1, color: colorScheme.outline.withOpacity(0.13)),
                        // Appearance section
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.primary)),
                              SizedBox(height: 10),
                              ...List.generate(AppTheme.themeNames.length, (i) => ListTile(
                                    leading: Icon(Icons.palette, color: i == _selectedThemeIndex ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.5)),
                                    title: Text(AppTheme.themeNames[i], style: TextStyle(fontWeight: i == _selectedThemeIndex ? FontWeight.bold : FontWeight.normal, fontSize: 16, color: colorScheme.onSurface)),
                                    trailing: i == _selectedThemeIndex ? Icon(Icons.check, color: colorScheme.primary) : null,
                                    onTap: () => _onThemeChanged(i),
                                  )),
                            ],
                          ),
                        ),
                        Divider(height: 0, thickness: 1, color: colorScheme.outline.withOpacity(0.13)),
                        // Account section (bottom rounded)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.primary)),
                              SizedBox(height: 10),
                              ListTile(
                                leading: Icon(Icons.account_circle, color: colorScheme.primary),
                                title: Text('Account Details', style: TextStyle(color: colorScheme.onSurface, fontSize: 16)),
                                trailing: Icon(Icons.arrow_forward_ios, size: 18, color: colorScheme.onSurface.withOpacity(0.5)),
                                onTap: () {},
                              ),
                              ListTile(
                                leading: Icon(Icons.privacy_tip, color: colorScheme.primary),
                                title: Text('Privacy', style: TextStyle(color: colorScheme.onSurface, fontSize: 16)),
                                trailing: Icon(Icons.arrow_forward_ios, size: 18, color: colorScheme.onSurface.withOpacity(0.5)),
                                onTap: () {},
                              ),
                              ListTile(
                                leading: Icon(Icons.help_outline, color: colorScheme.primary),
                                title: Text('Help & Support', style: TextStyle(color: colorScheme.onSurface, fontSize: 16)),
                                trailing: Icon(Icons.arrow_forward_ios, size: 18, color: colorScheme.onSurface.withOpacity(0.5)),
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 28),
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        elevation: 2,
                      ),
                      icon: Icon(Icons.logout),
                      label: Text('Log Out'),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
      ),
    );
  }
} 