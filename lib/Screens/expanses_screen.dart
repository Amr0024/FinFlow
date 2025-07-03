import 'package:flutter/material.dart';
import 'package:projects_flutter/services/firestore_services.dart'; // still here for saving

class ExpansesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final Function(
      String category,
      double amount,
      bool isNotPriority,
      String? productName,
      String? mandatoryLevel,
      ) onExpenseAdded;

  const ExpansesScreen({
    super.key,
    required this.categories,
    required this.onExpenseAdded,
  });

  @override
  State<ExpansesScreen> createState() => _ExpansesScreenState();
}

class _ExpansesScreenState extends State<ExpansesScreen> {
  // ───────────────────────── controllers / state
  final _amountCtrl      = TextEditingController();
  final _productNameCtrl = TextEditingController();

  /// The list shown in the drop‑down (defaults + user‑defined)
  late List<Map<String, dynamic>> _cats;

  String _selectedCatName = '';
  bool   _isNotPriority   = false;
  String _mandatoryLevel  = '';
  bool   _showNPBtn       = false;

  final List<Map<String, dynamic>> _nonPriorityItems = [];

  // ───────────────────────── fallback defaults (never saved to Firestore)
  static const _defaultCats = <Map<String, dynamic>>[
    {
      'name': 'Entertainment',
      'icon': Icons.movie,
      'color': Colors.purple,
    },
    {
      'name': 'Food',
      'icon': Icons.fastfood,
      'color': Colors.red,
    },
    {
      'name': 'Fashion',
      'icon': Icons.shopping_bag,
      'color': Colors.teal,
    },
    {
      'name': 'Bills',
      'icon': Icons.receipt,
      'color': Colors.blue,
    },
    {
      'name': 'Add Custom…',            // special sentinel
      'icon': Icons.add,
      'color': Colors.grey,
    },
  ];

  // ─────────────────────────── helper: current category Firestore id
  String? _currentCatId() {
    final cat = _cats.firstWhere(
          (c) => c['name'] == _selectedCatName,
      orElse: () => const {},          // no match → empty map
    );

    // guard: if there is no id or it isn’t a String, return null
    final id = cat['id'];
    return id is String ? id : null;
  }

  // initstate
  @override
  void initState() {
    super.initState();

    // Start with the built‑in defaults …
    _cats = [..._defaultCats];

    // merge categories coming from MainScreen / Firestore
    for (final c in widget.categories) {
      if (c['name'] == 'Add Custom…') continue;
      final exists = _cats.any((d) => d['name'] == c['name']);
      if (!exists) _cats.insert(_cats.length - 1, c);
    }

    // first real item as default selection
    _selectedCatName =
    _cats.firstWhere((c) => c['name'] != 'Add Custom…')['name'];
  }

  // UI helpers
  Widget _amountField() => _labelAnd(
    'Enter Amount',
    TextField(
      controller: _amountCtrl,
      keyboardType: TextInputType.number,
      decoration: _inputDeco('Enter Amount'),
    ),
  );

  Widget _productNameField() => _labelAnd(
    'Product Name',
    TextField(
      controller: _productNameCtrl,
      decoration: _inputDeco('Enter Product Name'),
    ),
  );

  Widget _categoryDropdown() => _labelAnd(
    'Select Category',
    DropdownButton<String>(
      value: _selectedCatName,
      isExpanded: true,
      onChanged: _onCatChanged,
      items: _cats.map<DropdownMenuItem<String>>((c) {
        return DropdownMenuItem(
          value: c['name'],
          child: Row(
            children: [
              Icon(c['icon'], color: c['color']),
              const SizedBox(width: 10),
              Text(c['name']),
            ],
          ),
        );
      }).toList(),
    ),
  );

  // category change / add custom
  void _onCatChanged(String? newValue) async {
    if (newValue == null) return;

    if (newValue == 'Add Custom…') {
      final created = await _showAddCatDialog();
      if (created != null) {
        await FirestoreService.addCategory(
          name : created['name'],
          icon : (created['icon'] as IconData).codePoint,
          color: (created['color'] as Color).value,
        );

        setState(() {
          _cats.insert(_cats.length - 1, created);
          _selectedCatName = created['name'];
        });
      }
    } else {
      setState(() => _selectedCatName = newValue);
    }
  }

  Future<Map<String, dynamic>?> _showAddCatDialog() {
    final nameCtrl = TextEditingController();
    IconData icon  = Icons.category;
    Color    color = Colors.orange;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: _inputDeco('Category name'),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: [
                Colors.red,
                Colors.green,
                Colors.blue,
                Colors.orange,
                Colors.purple,
              ].map((c) {
                return GestureDetector(
                  onTap: () => setState(() => color = c),
                  child: CircleAvatar(
                    backgroundColor: c,
                    radius: 14,
                    child: color == c ? const Icon(Icons.check, size: 16) : null,
                  ),
                );
              }).toList(),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop<Map<String, dynamic>>(context, {
                'name' : nameCtrl.text.trim(),
                'icon' : icon,
                'color': color,
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _nonPriorityToggle() => CheckboxListTile(
    title: const Text('Not a Priority Expense'),
    value: _isNotPriority,
    onChanged: (v) => setState(() {
      _isNotPriority = v ?? false;
      if (!_isNotPriority) _mandatoryLevel = '';
    }),
  );

  Widget _mandatoryChoices() => _labelAnd(
    'How Mandatory Was This Item?',
    Column(
      children: ['Low', 'Medium', 'High'].map((lvl) {
        return Row(
          children: [
            Checkbox(
              value: _mandatoryLevel == lvl,
              onChanged: (v) => setState(() => _mandatoryLevel = v! ? lvl : ''),
            ),
            Text(lvl),
          ],
        );
      }).toList(),
    ),
  );

  Widget _addExpenseButton() => SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: _handleAddExpense,
      child: const Text('Add Expense', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    ),
  );

  // ───────────────────────────── helper widgets
  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  );

  Widget _labelAnd(String label, Widget field) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      field,
      const SizedBox(height: 10),
    ],
  );

  // ───────────────────────────── logic
  Future<void> _handleAddExpense() async {
    // 1) basic validation ────────────────────────────────────────────
    if (_amountCtrl.text.isEmpty || _selectedCatName.isEmpty) {
      _showSnack('Please enter an amount and select a category.');
      return;
    }
    if (_isNotPriority && _productNameCtrl.text.isEmpty) {
      _showSnack('Please enter a product name.');
      return;
    }

    final amount = double.tryParse(_amountCtrl.text) ?? 0;

    try {
      // 2) write to Firestore (may throw) ────────────────────────────
      await FirestoreService.addTransaction(
        catId      : _currentCatId(),          // nullable for built‑ins
        amount     : -amount.abs(),            // expenses are negative
        notPriority: _isNotPriority,
        productName: _isNotPriority ? _productNameCtrl.text : null,
      );

      // 3) update UI in memory (callback to MainScreen) ──────────────
      widget.onExpenseAdded(
        _selectedCatName,
        amount,
        _isNotPriority,
        _isNotPriority ? _productNameCtrl.text : null,
        _isNotPriority ? _mandatoryLevel       : null,
      );

      // 4) local list for non‑priority items (unchanged) ─────────────
      if (_isNotPriority) {
        _nonPriorityItems.add({
          'name'          : _productNameCtrl.text,
          'amount'        : amount,
          'category'      : _selectedCatName,
          'mandatoryLevel': _mandatoryLevel,
        });
      }

      // 5) reset form fields ─────────────────────────────────────────
      setState(() {
        _amountCtrl.clear();
        _productNameCtrl.clear();
        _mandatoryLevel = '';
        _isNotPriority  = false;
        _showNPBtn      = _nonPriorityItems.isNotEmpty;
      });

      // 6) tell user *before* leaving the page, then pop ─────────────
      if (mounted) {
        _showSnack('Expense added successfully!');
        Navigator.pop(context);               // back to MainScreen
      }
    } catch (e) {
      // Any Firestore / network error ends up here
      if (mounted) {
        _showSnack('Failed to add expense. Please try again.\n$e');
      }
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ───────────────────────────────────────── build
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Add Expense', style: TextStyle(color: Colors.white)),
      iconTheme: const IconThemeData(color: Colors.white),
      backgroundColor: Colors.indigo,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _amountField(),
          _productNameField(),
          _categoryDropdown(),
          _nonPriorityToggle(),
          if (_isNotPriority) _mandatoryChoices(),
          const SizedBox(height: 10),
          _addExpenseButton(),
          const SizedBox(height: 30),
          if (_showNPBtn) _viewNonPriorityButton(),
        ],
      ),
    ),
  );

  Widget _viewNonPriorityButton() => SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Non‑Priority Items'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: _nonPriorityItems
                  .map((i) => ListTile(
                title: Text(i['name']),
                subtitle: Text(
                  'Amount: LE${i['amount'].toStringAsFixed(2)}\n'
                      'Category: ${i['category']}\n'
                      'Mandatory: ${i['mandatoryLevel']}',
                ),
              ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      ),
      child: const Text('View Non‑Priority Items'),
    ),
  );

  @override
  void dispose() {
    _amountCtrl.dispose();
    _productNameCtrl.dispose();
    super.dispose();
  }
}
