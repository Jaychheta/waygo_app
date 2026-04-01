import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../services/expense_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/custom_button.dart';
import '../widgets/animated_card.dart';

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
  final List<Map<String, dynamic>> members;
  final VoidCallback? onSaved;

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
        transitionDuration: 300.ms,
      ),
    );
  }

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _selectedCategory = 'Food';
  bool _saving = false;
  late final Map<int, bool> _splitWith;

  static const _categories = ['Food', 'Transport', 'Stay', 'Others'];
  static const _categoryIcons = {
    'Food': Icons.restaurant_rounded,
    'Transport': Icons.directions_car_rounded,
    'Stay': Icons.hotel_rounded,
    'Others': Icons.shopping_bag_outlined,
  };

  @override
  void initState() {
    super.initState();
    _splitWith = {for (final m in widget.members) (m['id'] as int): (m['id'] as int) != widget.currentUserId};
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final splitIds = _splitWith.entries.where((e) => e.value).map((e) => e.key).toList();
    final ok = await ExpenseService().addExpense(
      tripId: widget.tripId,
      paidBy: widget.currentUserId,
      amount: double.parse(_amountCtrl.text.trim()),
      category: _selectedCategory,
      description: _descCtrl.text.trim(),
      splitWith: splitIds,
    );
    if (mounted) {
      if (ok) {
        widget.onSaved?.call();
        Navigator.pop(context);
      } else {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: kWhite, size: 24),
        ),
        title: const Text('RECORD EXPENSE', style: TextStyle(color: kWhite, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildAmountInput(),
            const SizedBox(height: 48),
            _sectionHeader('CATEGORY'),
            const SizedBox(height: 16),
            _buildCategoryRow(),
            const SizedBox(height: 32),
            _sectionHeader('DESCRIPTION'),
            const SizedBox(height: 16),
            _buildGlassField(_descCtrl, 'e.g. Dinner at Taj', Icons.edit_note_rounded),
            const SizedBox(height: 32),
            _sectionHeader('SPLIT WITH'),
            const SizedBox(height: 16),
            _buildMemberListStack(),
            const SizedBox(height: 60),
            CustomButton(text: 'Log Transaction', isLoading: _saving, onPressed: _save),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      children: [
        Text('HOW MUCH?', style: TextStyle(color: kWhite.withValues(alpha: 0.2), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text('₹', style: TextStyle(color: kTeal, fontSize: 32, fontWeight: FontWeight.w900)),
            const SizedBox(width: 8),
            SizedBox(
              width: 180,
              child: TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(color: kWhite, fontSize: 56, fontWeight: FontWeight.w900, letterSpacing: -2),
                decoration: const InputDecoration(border: InputBorder.none, hintText: '0.00', hintStyle: TextStyle(color: kSlate)),
                validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? '' : null,
              ),
            ),
          ],
        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
      ],
    );
  }

  Widget _sectionHeader(String text) {
    return Text(text, style: TextStyle(color: kWhite.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2));
  }

  Widget _buildCategoryRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                radius: 12,
                opacity: isSelected ? 0.2 : 0.05,
                child: Row(
                  children: [
                    Icon(_categoryIcons[cat], color: isSelected ? kTeal : kWhite.withValues(alpha: 0.2), size: 16),
                    const SizedBox(width: 8),
                    Text(cat, style: TextStyle(color: isSelected ? kWhite : kWhite.withValues(alpha: 0.2), fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildGlassField(TextEditingController ctrl, String hint, IconData icon) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      radius: 16,
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: kWhite, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: kWhite.withValues(alpha: 0.15)),
          prefixIcon: Icon(icon, color: kTeal, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildMemberListStack() {
    return Column(
      children: widget.members.asMap().entries.map((entry) {
        final i = entry.key;
        final m = entry.value;
        final id = m['id'] as int;
        if (id == widget.currentUserId) return const SizedBox.shrink();
        final checked = _splitWith[id] ?? false;

        return AnimatedCard(
          index: i,
          onTap: () => setState(() => _splitWith[id] = !checked),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              opacity: checked ? 0.15 : 0.02,
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: kTeal.withValues(alpha: checked ? 1 : 0.1), radius: 15, child: Text(m['name'][0], style: const TextStyle(color: kWhite, fontSize: 12))),
                  const SizedBox(width: 16),
                  Text(m['name'], style: TextStyle(color: checked ? kWhite : kWhite.withValues(alpha: 0.3), fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Icon(checked ? Icons.check_circle_rounded : Icons.radio_button_off_rounded, color: checked ? kTeal : kWhite.withValues(alpha: 0.1), size: 18),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 600.ms);
  }
}
