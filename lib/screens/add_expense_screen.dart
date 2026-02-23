import 'package:flutter/material.dart';
import 'package:waygo_app/config/app_theme.dart';
import 'package:waygo_app/services/expense_service.dart';

/// Modal bottom-sheet style full-screen form for adding a new expense.
/// Push this via [AddExpenseScreen.show] for a smooth slide-up presentation.
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({
    super.key,
    required this.tripId,
    required this.currentUserId,
    required this.currentUserName,
    required this.members,
    this.onSaved,
  });

  final int tripId;
  final int currentUserId;
  final String currentUserName;

  /// List of all group members: each map has 'id' (int) and 'name' (String).
  final List<Map<String, dynamic>> members;

  /// Called after a successful save so the parent can refresh its list.
  final VoidCallback? onSaved;

  /// Convenience helper to push as a full-screen route.
  static Future<void> show(
    BuildContext context, {
    required int tripId,
    required int currentUserId,
    required String currentUserName,
    required List<Map<String, dynamic>> members,
    VoidCallback? onSaved,
  }) {
    return Navigator.of(context).push<void>(
      PageRouteBuilder(
        pageBuilder: (ctx, animation, secondary) => FadeTransition(
          opacity: animation,
          child: AddExpenseScreen(
            tripId: tripId,
            currentUserId: currentUserId,
            currentUserName: currentUserName,
            members: members,
            onSaved: onSaved,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _selectedCategory = 'Food';
  bool _saving = false;

  // splitWith: track which member IDs are checked (exclude self initially)
  late final Map<int, bool> _splitWith;

  static const _categories = ['Food', 'Transport', 'Stay', 'Others'];

  static const _categoryIcons = <String, IconData>{
    'Food': Icons.restaurant_rounded,
    'Transport': Icons.directions_car_rounded,
    'Stay': Icons.hotel_rounded,
    'Others': Icons.shopping_bag_outlined,
  };

  static const _categoryColors = <String, Color>{
    'Food': Color(0xFFEA580C),
    'Transport': Color(0xFF3B82F6),
    'Stay': Color(0xFF8B5CF6),
    'Others': kTeal,
  };

  @override
  void initState() {
    super.initState();
    // Pre-check all members except current user for split
    _splitWith = {
      for (final m in widget.members)
        (m['id'] as int): (m['id'] as int) != widget.currentUserId,
    };
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final splitIds = _splitWith.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final ok = await ExpenseService().addExpense(
      tripId: widget.tripId,
      paidBy: widget.currentUserId,
      amount: double.parse(_amountCtrl.text.trim()),
      category: _selectedCategory,
      description: _descCtrl.text.trim(),
      splitWith: splitIds,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      widget.onSaved?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: kWhite, size: 18),
              SizedBox(width: 10),
              Text('Expense saved!', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: kTeal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius12)),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_rounded, color: kWhite, size: 18),
              SizedBox(width: 10),
              Text('Failed to save. Try again.'),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      appBar: AppBar(
        backgroundColor: kNavy,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kNavy2,
              borderRadius: BorderRadius.circular(kRadius12),
              border: Border.all(color: kWhite.withValues(alpha: 0.08)),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: kWhite, size: 20),
          ),
        ),
        title: const Text(
          'Add Expense',
          style: TextStyle(fontWeight: FontWeight.w800, color: kWhite, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            _buildAmountField(),
            const SizedBox(height: 24),
            _buildCategorySelector(),
            const SizedBox(height: 24),
            _buildDescriptionField(),
            const SizedBox(height: 24),
            _buildPaidBySection(),
            const SizedBox(height: 24),
            _buildSplitWithSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildSaveButton(),
    );
  }

  // ─── Amount ────────────────────────────────────────────────────────────────
  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('AMOUNT'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: kNavy2,
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: kWhite.withValues(alpha: 0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('₹',
                  style: TextStyle(
                      color: kTeal, fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                      color: kWhite,
                      fontSize: 32,
                      fontWeight: FontWeight.w800),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                        color: kSlate,
                        fontSize: 32,
                        fontWeight: FontWeight.w700),
                    border: InputBorder.none,
                    filled: false,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 14),
                  ),
                  validator: (v) {
                    final val = double.tryParse(v?.trim() ?? '');
                    if (val == null || val <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Category ──────────────────────────────────────────────────────────────
  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('CATEGORY'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: kNavy2,
            borderRadius: BorderRadius.circular(kRadius12),
            border: Border.all(color: kWhite.withValues(alpha: 0.08)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              dropdownColor: kNavy2,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: kSlate),
              items: _categories.map((cat) {
                final color =
                    _categoryColors[cat] ?? kTeal;
                return DropdownMenuItem(
                  value: cat,
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_categoryIcons[cat], color: color, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Text(cat,
                          style: const TextStyle(
                              color: kWhite,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ─── Description ──────────────────────────────────────────────────────────
  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('DESCRIPTION'),
        const SizedBox(height: 10),
        TextFormField(
          controller: _descCtrl,
          maxLines: 3,
          style: const TextStyle(color: kWhite, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'What was this expense for?',
            hintStyle: const TextStyle(color: kSlate),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 42),
              child: Icon(Icons.edit_note_rounded, color: kSlate, size: 22),
            ),
            filled: true,
            fillColor: kNavy2,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadius12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadius12),
                borderSide:
                    BorderSide(color: kWhite.withValues(alpha: 0.08))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadius12),
                borderSide: const BorderSide(color: kTeal, width: 1.5)),
          ),
        ),
      ],
    );
  }

  // ─── Paid By ──────────────────────────────────────────────────────────────
  Widget _buildPaidBySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('PAID BY'),
        const SizedBox(height: 12),
        // Always defaulted to current user — locked chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: kNavy2,
            borderRadius: BorderRadius.circular(kRadius12),
            border: Border.all(color: kTeal.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, gradient: kTealGradient),
                child: Center(
                  child: Text(
                    widget.currentUserName.isNotEmpty
                        ? widget.currentUserName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                        color: kWhite,
                        fontWeight: FontWeight.w800,
                        fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.currentUserName,
                      style: const TextStyle(
                          color: kWhite,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const Text('You (current user)',
                      style: TextStyle(color: kSlate, fontSize: 11)),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: kTeal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Paying',
                    style: TextStyle(
                        color: kTeal,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Split With ───────────────────────────────────────────────────────────
  Widget _buildSplitWithSection() {
    final others = widget.members
        .where((m) => (m['id'] as int) != widget.currentUserId)
        .toList();

    if (others.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('SPLIT WITH'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kNavy2,
              borderRadius: BorderRadius.circular(kRadius12),
            ),
            child: const Text('No other members in this group.',
                style: TextStyle(color: kSlate, fontSize: 13)),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _label('SPLIT WITH'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: kTeal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_splitWith.values.where((v) => v).length} selected',
                style: const TextStyle(
                    color: kTeal, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: kNavy2,
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: kWhite.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: others.asMap().entries.map((entry) {
              final i = entry.key;
              final m = entry.value;
              final id = m['id'] as int;
              final name = m['name'] as String;
              final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
              final isLast = i == others.length - 1;
              final checked = _splitWith[id] ?? false;

              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.vertical(
                        top: i == 0
                            ? const Radius.circular(kRadius)
                            : Radius.zero,
                        bottom: isLast
                            ? const Radius.circular(kRadius)
                            : Radius.zero,
                      ),
                      onTap: () =>
                          setState(() => _splitWith[id] = !checked),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: kNavy3,
                                border: Border.all(
                                    color: checked
                                        ? kTeal.withValues(alpha: 0.5)
                                        : kWhite.withValues(alpha: 0.1)),
                              ),
                              child: Center(
                                child: Text(initial,
                                    style: TextStyle(
                                        color:
                                            checked ? kTeal : kSlate,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                    color: checked ? kWhite : kSlate,
                                    fontWeight: checked
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 15),
                              ),
                            ),
                            // Checkbox
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: checked
                                    ? kTeal
                                    : Colors.transparent,
                                border: Border.all(
                                    color: checked
                                        ? kTeal
                                        : kSlate.withValues(alpha: 0.4),
                                    width: 2),
                              ),
                              child: checked
                                  ? const Icon(Icons.check_rounded,
                                      color: kWhite, size: 15)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(
                        height: 1,
                        color: kWhite.withValues(alpha: 0.05),
                        indent: 70),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Save Button ──────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: GestureDetector(
          onTap: _saving ? null : _save,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              gradient: _saving ? null : kTealGradient,
              color: _saving ? kNavy2 : null,
              borderRadius: BorderRadius.circular(kRadius),
              boxShadow: _saving
                  ? []
                  : [
                      BoxShadow(
                          color: kTeal.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8))
                    ],
            ),
            child: Center(
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: kTeal, strokeWidth: 2.5),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.save_rounded, color: kWhite, size: 20),
                        SizedBox(width: 10),
                        Text('Save Expense',
                            style: TextStyle(
                                color: kWhite,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helper ───────────────────────────────────────────────────────────────
  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            color: kSlate,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5),
      );
}
