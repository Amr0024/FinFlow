//notes_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> categories;

  NotesScreen({required this.categories});

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
    final _formKey = GlobalKey<FormState>();
    final _noteController = TextEditingController();
    final _amountController = TextEditingController();
    DateTime _selectedDate = DateTime.now();
    String _selectedCategory = widget.categories.isNotEmpty
        ? widget.categories[0]['name']
        : 'Unknown';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: EdgeInsets.symmetric(horizontal: 40),
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Add Note',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'Note',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(fontSize: 22),
                      ),
                      style: TextStyle(fontSize: 22),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a note';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(fontSize: 22),
                      ),
                      style: TextStyle(fontSize: 22),
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
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        DateFormat('yyyy-MM-dd').format(_selectedDate),
                        style: TextStyle(fontSize: 22),
                      ),
                      trailing: Icon(Icons.calendar_today, size: 30),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null && picked != _selectedDate) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(fontSize: 22),
                      ),
                      style: TextStyle(fontSize: 22, color: Colors.black),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue!;
                        });
                      },
                      items: widget.categories.map<DropdownMenuItem<String>>(
                              (Map<String, dynamic> category) {
                            return DropdownMenuItem<String>(
                              value: category['name'],
                              child: Row(
                                children: <Widget>[
                                  Icon(category['icon'], color: Colors.black, size: 28),
                                  SizedBox(width: 10),
                                  Text(
                                    category['name'],
                                    style: TextStyle(fontSize: 22, color: Colors.black),
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
                          child: Text('Cancel', style: TextStyle(fontSize: 22)),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              setState(() {
                                _notes.add({
                                  'note': _noteController.text,
                                  'amount': double.parse(_amountController.text),
                                  'date': _selectedDate,
                                  'category': _selectedCategory,
                                });
                              });
                              _saveNotes(); // Save notes to persistent storage
                              Navigator.pop(context); // Close the dialog
                            }
                          },
                          child: Text('Save', style: TextStyle(fontSize: 22)),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Notes', style: TextStyle(fontSize: 24)),
      ),
      body: ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          final note = _notes[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
                        color: Colors.black,
                        size: 32,
                      ),
                      SizedBox(width: 15),
                      Text(
                        note['note'],
                        style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Amount: \$${note['amount'].toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 20),
                      ),
                      Spacer(),
                      Text(
                        'Date: ${DateFormat('yyyy-MM-dd').format(note['date'])}',
                        style: TextStyle(fontSize: 20),
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
          shape: CircleBorder(),
          child: Icon(Icons.add, size: 50),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notes),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: 1,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context); // Go back to the home screen
          }
        },
      ),
    );
  }
}