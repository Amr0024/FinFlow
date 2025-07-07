import 'package:flutter/material.dart';
import 'package:projects_flutter/services/firestore_services.dart';
import '../theme/app_theme.dart';

class ExpansesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final int themeIndex;
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
    this.themeIndex = 0,
  });

  @override
  State<ExpansesScreen> createState() => _ExpansesScreenState();
}

class _ExpansesScreenState extends State<ExpansesScreen> {
  final _amountCtrl = TextEditingController();
  final _productNameCtrl = TextEditingController();

  late List<Map<String, dynamic>> _cats;
  String _selectedCatName = '';
  bool _isNotPriority = false;
  String _mandatoryLevel = '';
  bool _showNPBtn = false;
  bool _showCategoryModal = false;

  final List<Map<String, dynamic>> _nonPriorityItems = [];

  String? _currentCatId() {
    final cat = _cats.firstWhere(
          (c) => c['name'] == _selectedCatName,
      orElse: () => const {},
    );
    final id = cat['id'];
    return id is String ? id : null;
  }

  @override
  void initState() {
    super.initState();
    _cats = widget.categories.where((c) => c['name'] != 'Add Custom…' && c['name'] != 'Add Category').toList();
    _selectedCatName = '';
    _amountCtrl.addListener(() => setState(() {}));
    _productNameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _productNameCtrl.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    final colorScheme = AppTheme.themes[widget.themeIndex];
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 24 + topPadding, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 26),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.add_shopping_cart,
              color: Colors.white,
              size: 22,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Add Expense',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Track your spending',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    final colorScheme = AppTheme.themes[widget.themeIndex];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _amountCtrl,
        keyboardType: TextInputType.number,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: '0.00',
          hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.3)),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.attach_money, color: colorScheme.primary),
          ),
          suffixText: 'LE',
          suffixStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildProductNameField() {
    final colorScheme = AppTheme.themes[widget.themeIndex];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _productNameCtrl,
        style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'What did you buy?',
          hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.3)),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.shopping_bag, color: colorScheme.secondary),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final colorScheme = AppTheme.themes[widget.themeIndex];
    final selectedCategory = _cats.firstWhere(
      (c) => c['name'] == _selectedCatName,
      orElse: () => {},
    );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              'Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showCategoryModal = true),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.18),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (selectedCategory.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (selectedCategory['color'] as Color).withOpacity(0.13),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        selectedCategory['icon'],
                        color: selectedCategory['color'],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        selectedCategory['name'] ?? 'Select Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.category,
                        color: colorScheme.primary.withOpacity(0.25),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Select Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary.withOpacity(0.35),
                        ),
                      ),
                    ),
                  ],
                  Icon(
                    Icons.arrow_drop_down,
                    color: colorScheme.primary.withOpacity(0.35),
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityToggle() {
    final colorScheme = AppTheme.themes[widget.themeIndex];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.secondary.withOpacity(0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isNotPriority ? colorScheme.secondary.withOpacity(0.13) : colorScheme.primary.withOpacity(0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isNotPriority ? Icons.priority_high : Icons.check_circle,
              color: _isNotPriority ? colorScheme.secondary : colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isNotPriority ? 'Non-Priority Expense' : 'Priority Expense',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  _isNotPriority 
                      ? 'This is an optional purchase'
                      : 'This is an essential expense',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isNotPriority,
            onChanged: (value) => setState(() {
              _isNotPriority = value;
              if (!_isNotPriority) _mandatoryLevel = '';
            }),
            activeColor: colorScheme.secondary,
            activeTrackColor: colorScheme.secondary.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildMandatoryChoices() {
    final colorScheme = AppTheme.themes[widget.themeIndex];
    if (!_isNotPriority) return const SizedBox.shrink();

    final levels = ['Low', 'Medium', 'High'];
    final selectedIdx = levels.indexOf(_mandatoryLevel);
    final barHeight = 10.0;
    final pointSize = 28.0;
    final selectedPointSize = 34.0;
    final barGradient = LinearGradient(
      colors: [colorScheme.primary, colorScheme.secondary],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.13),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How necessary was this?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth - 24; // padding for points
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: selectedIdx >= 0 ? selectedIdx / 2 : 0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Carved (neumorphic) bar
                      Container(
                        width: barWidth,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(barHeight/2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.8),
                              offset: const Offset(-2, -2),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              offset: const Offset(2, 2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      // Filled bar (gradient)
                      Positioned(
                        left: 0,
                        child: Container(
                          width: barWidth * value,
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: barGradient,
                            borderRadius: BorderRadius.circular(barHeight/2),
                          ),
                        ),
                      ),
                      // Points
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(3, (i) {
                          final isFilled = selectedIdx >= i && selectedIdx >= 0;
                          final isSelected = selectedIdx == i;
                          return GestureDetector(
                            onTap: () => setState(() => _mandatoryLevel = levels[i]),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              width: isSelected ? selectedPointSize : pointSize,
                              height: isSelected ? selectedPointSize : pointSize,
                              decoration: BoxDecoration(
                                color: isFilled ? null : Colors.white,
                                gradient: isFilled ? barGradient : null,
                                border: Border.all(
                                  color: isFilled ? colorScheme.primary : colorScheme.outline,
                                  width: isSelected ? 3 : 2,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  if (isFilled || isSelected)
                                    BoxShadow(
                                      color: colorScheme.primary.withOpacity(0.13),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  if (!isFilled && !isSelected) ...[
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.95),
                                      offset: const Offset(-2, -2),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.07),
                                      offset: const Offset(2, 2),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) =>
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selectedIdx == i ? FontWeight.bold : FontWeight.w600,
                  color: selectedIdx == i ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.5),
                ),
                child: Text(levels[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    final colorScheme = AppTheme.themes[widget.themeIndex];
    final isValid = _amountCtrl.text.isNotEmpty && (!_isNotPriority || _productNameCtrl.text.isNotEmpty);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isValid ? colorScheme.primary : colorScheme.surfaceVariant,
          foregroundColor: isValid ? colorScheme.onPrimary : colorScheme.onSurface.withOpacity(0.5),
          elevation: isValid ? 8 : 0,
          shadowColor: colorScheme.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: isValid ? _handleAddExpense : null,
        child: const Text(
          'Add Expense',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryModal() {
    final colorScheme = AppTheme.themes[widget.themeIndex];
    if (!_showCategoryModal) return const SizedBox.shrink();
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => setState(() => _showCategoryModal = false),
            child: Container(
              color: colorScheme.shadow.withOpacity(0.5),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.category,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Select Category',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: _cats.length,
                    itemBuilder: (context, index) {
                      final category = _cats[index];
                      final isSelected = category['name'] == _selectedCatName;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCatName = category['name'];
                            _showCategoryModal = false;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? (category['color'] as Color).withOpacity(0.1)
                                : colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected 
                                  ? category['color'] as Color
                                  : colorScheme.outline,
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: (category['color'] as Color).withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ] : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? category['color'] as Color
                                      : colorScheme.surface,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.shadow.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  category['icon'],
                                  color: isSelected 
                                      ? colorScheme.onPrimary
                                      : category['color'] as Color,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                category['name'],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected 
                                      ? category['color'] as Color
                                      : colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAddExpense() async {
    if (_amountCtrl.text.isEmpty) {
      _showSnack('Please enter an amount.');
      return;
    }
    if (_isNotPriority && _productNameCtrl.text.isEmpty) {
      _showSnack('Please enter a product name.');
      return;
    }
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    try {
      widget.onExpenseAdded(
        _selectedCatName,
        amount,
        _isNotPriority,
        _isNotPriority ? _productNameCtrl.text : null,
        _isNotPriority ? _mandatoryLevel : null,
      );
      if (_isNotPriority) {
        _nonPriorityItems.add({
          'name': _productNameCtrl.text,
          'amount': amount,
          'category': _selectedCatName,
          'mandatoryLevel': _mandatoryLevel,
        });
      }
      setState(() {
        _amountCtrl.clear();
        _productNameCtrl.clear();
        _mandatoryLevel = '';
        _isNotPriority = false;
        _showNPBtn = _nonPriorityItems.isNotEmpty;
      });
      if (mounted) {
        _showSnack('Expense added successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to add expense. Please try again.\n$e');
      }
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.grey.shade50,
    body: SafeArea(
      bottom: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildAmountField(),
              _buildProductNameField(),
              _buildCategorySelector(),
              _buildPriorityToggle(),
              _buildMandatoryChoices(),
              _buildAddButton(),
              if (_showNPBtn) _viewNonPriorityButton(),
          const SizedBox(height: 30),
        ],
      ),
        ),
        _buildCategoryModal(),
      ],
    ),
    ),
  );

  Widget _viewNonPriorityButton() {
    final colorScheme = AppTheme.themes[widget.themeIndex];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.list_alt),
        label: const Text('View Non-Priority Items'),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Non-Priority Items'),
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
      ),
    );
  }
} 