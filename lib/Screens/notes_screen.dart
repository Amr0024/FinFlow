//notes_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/app_theme.dart';

class NotesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final int themeIndex;
  final Function(int)? onThemeUpdated;

  const NotesScreen({
    super.key, 
    required this.categories,
    this.themeIndex = 0,
    this.onThemeUpdated,
  });

  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Map<String, dynamic>> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes(); // Load notes when the screen is first created
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadNotes(); // Load notes when dependencies change (e.g., coming back to the screen)
  }

  Future<void> _loadNotes() async {
    print("Loading notes..."); // Debug print
    final prefs = await SharedPreferences.getInstance();
    final savedNotes = prefs.getString('notes');
    if (savedNotes != null) {
      setState(() {
        _notes = List<Map<String, dynamic>>.from(json.decode(savedNotes));
        print("Loaded notes: $_notes"); // Debug print
      });
    } else {
      print("No notes found in SharedPreferences."); // Debug print
    }
  }

  Future<void> _saveNotes() async {
    print("Saving notes..."); // Debug print
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('notes', json.encode(_notes));
    print("Saved notes: $_notes"); // Debug print
  }

  void _showAddNoteDialog() {
    final formKey = GlobalKey<FormState>();
    final noteController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedCategory = widget.categories.isNotEmpty
        ? widget.categories[0]['name']
        : 'Unknown';

    final colorScheme = AppTheme.themes[widget.themeIndex];
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: EdgeInsets.symmetric(horizontal: 40),
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Add Note',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: 'Note',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(fontSize: 22, color: colorScheme.onSurface),
                      ),
                      style: TextStyle(fontSize: 22, color: colorScheme.onSurface),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a note';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(fontSize: 22, color: colorScheme.onSurface),
                      ),
                      style: TextStyle(fontSize: 22, color: colorScheme.onSurface),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    ListTile(
                      title: Text(
                        "Date",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                      ),
                      subtitle: Text(
                        DateFormat('yyyy-MM-dd').format(selectedDate),
                        style: TextStyle(fontSize: 22, color: colorScheme.onSurface),
                      ),
                      trailing: Icon(Icons.calendar_today, size: 30, color: colorScheme.primary),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null && picked != selectedDate) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(fontSize: 22, color: colorScheme.onSurface),
                      ),
                      style: TextStyle(fontSize: 22, color: colorScheme.onSurface),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCategory = newValue!;
                        });
                      },
                      items: widget.categories.map<DropdownMenuItem<String>>(
                              (Map<String, dynamic> category) {
                            return DropdownMenuItem<String>(
                              value: category['name'],
                              child: Row(
                                children: <Widget>[
                                  Icon(category['icon'], color: colorScheme.primary, size: 28),
                                  SizedBox(width: 10),
                                  Text(
                                    category['name'],
                                    style: TextStyle(fontSize: 22, color: colorScheme.onSurface),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel', style: TextStyle(fontSize: 22, color: colorScheme.primary)),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              setState(() {
                                _notes.add({
                                  'note': noteController.text,
                                  'amount': double.parse(amountController.text),
                                  'date': selectedDate,
                                  'category': selectedCategory,
                                });
                              });
                              _saveNotes(); // Save notes to persistent storage
                              Navigator.pop(context); // Close the dialog
                            }
                          },
                          child: Text('Save', style: TextStyle(fontSize: 22, color: colorScheme.onPrimary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.themes[widget.themeIndex];
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.getPrimaryGradient(colorScheme),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.notes, color: colorScheme.primary),
              SizedBox(width: 10),
              Text('Notes', style: TextStyle(color: colorScheme.onBackground, fontWeight: FontWeight.bold, fontSize: 22)),
            ],
          ),
          backgroundColor: colorScheme.background.withOpacity(0.95),
          iconTheme: IconThemeData(color: colorScheme.onBackground),
          elevation: 1,
        ),
      body: ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          final note = _notes[index];
          return Container(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.categories.firstWhere(
                                (cat) => cat['name'] == note['category'])['icon'],
                        color: colorScheme.primary,
                        size: 32,
                      ),
                      SizedBox(width: 15),
                      Text(
                        note['note'],
                        style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Amount: \$${note['amount'].toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 20, color: colorScheme.onSurface),
                      ),
                      Spacer(),
                      Text(
                        'Date: ${DateFormat('yyyy-MM-dd').format(note['date'])}',
                        style: TextStyle(fontSize: 20, color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: SizedBox(
        width: 100,
        height: 100,
        child: FloatingActionButton(
          onPressed: _showAddNoteDialog,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: CircleBorder(),
          child: Icon(Icons.add, size: 50),
        ),
      ),
        // No bottom navigation here - it's handled by the parent container
      ),
    );
  }
}