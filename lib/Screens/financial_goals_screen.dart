import 'package:flutter/material.dart';
import '../services/firestore_services.dart';
import '../theme/app_theme.dart';

class FinancialGoalsScreen extends StatefulWidget {
  final ColorScheme colorScheme;
  final int themeIndex;
  final Function(int)? onThemeUpdated;
  
  const FinancialGoalsScreen({
    super.key, 
    required this.colorScheme,
    this.themeIndex = 0,
    this.onThemeUpdated,
  });

  @override
  State<FinancialGoalsScreen> createState() => _FinancialGoalsScreenState();
}

class _FinancialGoalsScreenState extends State<FinancialGoalsScreen> {
  List<Map<String, dynamic>> _goals = [];
  bool _loading = true;
  final List<String> _goalOptions = [
    'Save for a big purchase',
    'Build an emergency fund',
    'Pay off debt',
    'Invest for the future',
    'Travel',
    'Other',
  ];
  List<bool> _editingGoalName = [false, false];
  List<FocusNode> _targetFocusNodes = [FocusNode(), FocusNode()];
  List<FocusNode> _savedFocusNodes = [FocusNode(), FocusNode()];
  List<bool> _editingTarget = [false, false];
  List<bool> _editingSaved = [false, false];
  List<String> _customGoalNames = ['', ''];

  @override
  void initState() {
    super.initState();
    _fetchGoals();
    for (int i = 0; i < 2; i++) {
      _targetFocusNodes[i].addListener(() => _onFocusChange(i, 'target'));
      _savedFocusNodes[i].addListener(() => _onFocusChange(i, 'saved'));
    }
  }

  @override
  void dispose() {
    for (final node in _targetFocusNodes) {
      node.dispose();
    }
    for (final node in _savedFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onFocusChange(int i, String field) {
    if (field == 'target' && !_targetFocusNodes[i].hasFocus) {
      setState(() => _editingTarget[i] = false);
    }
    if (field == 'saved' && !_savedFocusNodes[i].hasFocus) {
      setState(() => _editingSaved[i] = false);
    }
  }

  Future<void> _fetchGoals() async {
    final goals = await FirestoreService.getFinancialGoals();
    setState(() {
      _goals = goals.length == 2
          ? goals
          : List.generate(2, (i) => {'name': '', 'target': 0.0, 'saved': 0.0});
      _customGoalNames = List.generate(2, (i) {
        final name = _goals[i]['name'] ?? '';
        if (name.isNotEmpty && !_goalOptions.contains(name)) {
          return name;
        }
        return '';
      });
      _loading = false;
    });
  }

  void _updateGoal(int index, String field, dynamic value) {
    setState(() {
      _goals[index][field] = value;
    });
  }

  Future<void> _saveGoals() async {
    await FirestoreService.setFinancialGoals(_goals);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Goals updated!')),
    );
  }

  void _showGoalPicker(int i) async {
    String? selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String? tempSelected = _goals[i]['name'];
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ..._goalOptions.map((g) => ListTile(
                    title: Text(g),
                    trailing: tempSelected == g
                        ? Icon(Icons.check,
                        color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () {
                      setModalState(() {
                        tempSelected = g;
                      });
                      Navigator.pop(context, g);
                    },
                  )),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (tempSelected != null) {
                        Navigator.pop(context, tempSelected);
                      }
                    },
                    child: const Text('Select'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (selected != null) {
      setState(() {
        if (selected == 'Other') {
          _goals[i]['name'] = 'Other';
          _customGoalNames[i] = '';
          _editingGoalName[i] = true; // Trigger edit mode in card
        } else {
          _goals[i]['name'] = selected;
          _customGoalNames[i] = selected;
          _editingGoalName[i] = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final cardColor = isDark ? colorScheme.surface : Colors.white;
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.getPrimaryGradient(colorScheme),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Your Financial Goals',
              style: AppTheme.getHeadingStyle(colorScheme)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: colorScheme.onBackground),
        ),
        // No bottom navigation here - it's handled by the parent container
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
            child: Column(
              children: [
                ...List.generate(2, (i) {
                  final goal = _goals[i];
                  final progress = (goal['target'] ?? 0) > 0
                      ? ((goal['saved'] ?? 0) / (goal['target'] ?? 1))
                      .clamp(0.0, 1.0)
                      : 0.0;
                  final isOther = goal['name'] == 'Other' ||
                      (_goalOptions.contains(goal['name']) == false &&
                          goal['name'].isNotEmpty);
                  final customName = _customGoalNames[i];
                  return Container(
                    margin: EdgeInsets.only(
                        top: i == 0 ? 18 : 0, bottom: 36),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(minHeight: 190),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: colorScheme.primary.withOpacity(0.15),
                          width: 1.5),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Main content (not Positioned)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 80, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.flag,
                                      color: colorScheme.primary,
                                      size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: isOther
                                              ? (_editingGoalName[i]
                                                  ? TextFormField(
                                                      autofocus: true,
                                                      initialValue: customName,
                                                      decoration: InputDecoration(
                                                        hintText: 'Enter your goal',
                                                        border: InputBorder.none,
                                                        isDense: true,
                                                        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                                                        hintStyle: TextStyle(color: Colors.grey),
                                                      ),
                                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: colorScheme.onSurface),
                                                      onChanged: (val) {
                                                        setState(() {
                                                          _customGoalNames[i] = val;
                                                          _goals[i]['name'] = val.isEmpty ? 'Other' : val;
                                                        });
                                                      },
                                                      onFieldSubmitted: (_) => setState(() => _editingGoalName[i] = false),
                                                      onEditingComplete: () => setState(() => _editingGoalName[i] = false),
                                                      onTapOutside: (_) => setState(() => _editingGoalName[i] = false),
                                                    )
                                                  : GestureDetector(
                                                      onTap: () => setState(() => _editingGoalName[i] = true),
                                                      child: Text(
                                                        customName.isNotEmpty ? customName : 'Other',
                                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: colorScheme.onSurface),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ))
                                              : Text(
                                            goal['name'].isNotEmpty
                                                ? goal['name']
                                                : 'Select goal',
                                            style: TextStyle(
                                                fontWeight:
                                                FontWeight.bold,
                                                fontSize: 22,
                                                color: colorScheme
                                                    .onSurface),
                                            maxLines: 1,
                                            overflow: TextOverflow
                                                .ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text('Target',
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: colorScheme
                                                    .secondary,
                                                fontWeight:
                                                FontWeight.w600)),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.white10
                                                : Colors.grey[100],
                                            borderRadius:
                                            BorderRadius.circular(16),
                                            border: Border.all(
                                                color: colorScheme.primary
                                                    .withOpacity(0.18),
                                                width: 1.5),
                                            boxShadow: [
                                              BoxShadow(
                                                color: isDark
                                                    ? Colors.black
                                                    .withOpacity(0.10)
                                                    : Colors.grey
                                                    .withOpacity(0.10),
                                                blurRadius: 8,
                                                offset:
                                                const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Focus(
                                            focusNode:
                                            _targetFocusNodes[i],
                                            child: TextFormField(
                                              initialValue: goal['target']
                                                  .toString(),
                                              keyboardType:
                                              TextInputType.number,
                                              decoration:
                                              const InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                EdgeInsets.symmetric(
                                                    vertical: 16,
                                                    horizontal: 18),
                                                border: InputBorder.none,
                                              ),
                                              style: TextStyle(
                                                  fontWeight:
                                                  FontWeight.bold,
                                                  fontSize: 20,
                                                  color: colorScheme
                                                      .onSurface),
                                              onChanged: (val) =>
                                                  _updateGoal(
                                                      i,
                                                      'target',
                                                      double.tryParse(
                                                          val) ??
                                                          0.0),
                                              onTap: () => setState(
                                                      () => _editingTarget[
                                                  i] = true),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text('Saved',
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: colorScheme
                                                    .secondary,
                                                fontWeight:
                                                FontWeight.w600)),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.white10
                                                : Colors.grey[100],
                                            borderRadius:
                                            BorderRadius.circular(16),
                                            border: Border.all(
                                                color: colorScheme.primary
                                                    .withOpacity(0.18),
                                                width: 1.5),
                                            boxShadow: [
                                              BoxShadow(
                                                color: isDark
                                                    ? Colors.black
                                                    .withOpacity(0.10)
                                                    : Colors.grey
                                                    .withOpacity(0.10),
                                                blurRadius: 8,
                                                offset:
                                                const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Focus(
                                            focusNode:
                                            _savedFocusNodes[i],
                                            child: TextFormField(
                                              initialValue: goal['saved']
                                                  .toString(),
                                              keyboardType:
                                              TextInputType.number,
                                              decoration:
                                              const InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                EdgeInsets.symmetric(
                                                    vertical: 16,
                                                    horizontal: 18),
                                                border: InputBorder.none,
                                              ),
                                              style: TextStyle(
                                                  fontWeight:
                                                  FontWeight.bold,
                                                  fontSize: 20,
                                                  color: colorScheme
                                                      .onSurface),
                                              onChanged: (val) =>
                                                  _updateGoal(
                                                      i,
                                                      'saved',
                                                      double.tryParse(
                                                          val) ??
                                                          0.0),
                                              onTap: () => setState(
                                                      () => _editingSaved[
                                                  i] = true),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Pen icon
                        Positioned(
                          top: 16,
                          right: 84,
                          child: IconButton(
                            icon: Icon(Icons.edit, color: colorScheme.primary, size: 24),
                            onPressed: () {
                              _showGoalPicker(i);
                            },
                            tooltip: 'Edit Goal',
                          ),
                        ),
                        // Progress indicator
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            width: 60,
                            height: 60,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark ? Colors.white10 : Colors.grey[100],
                                  ),
                                ),
                                SizedBox(
                                  width: 54,
                                  height: 54,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 4,
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 40),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppTheme.getPrimaryGradient(colorScheme),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _saveGoals,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20),
                      elevation: 0,
                    ),
                    child: const Text('Save Goals',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}