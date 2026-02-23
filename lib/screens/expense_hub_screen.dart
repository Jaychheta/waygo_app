import 'package:flutter/material.dart';
import 'package:waygo_app/config/app_theme.dart';
import 'package:waygo_app/models/expense_model.dart';
import 'package:waygo_app/screens/add_expense_screen.dart';

class ExpenseHubScreen extends StatefulWidget {
  const ExpenseHubScreen({super.key});

  @override
  State<ExpenseHubScreen> createState() => _ExpenseHubScreenState();
}

class _ExpenseHubScreenState extends State<ExpenseHubScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ── Mock data (replace with real API calls) ────────────────────────────────
  static const int _currentUserId = 1;
  static const String _currentUserName = 'You';

  final List<Map<String, dynamic>> _members = const [
    {'id': 1, 'name': 'You'},
    {'id': 2, 'name': 'Ansh'},
    {'id': 3, 'name': 'Sarah'},
    {'id': 4, 'name': 'Riya'},
  ];

  final List<ExpenseModel> _expenses = [
    ExpenseModel(
        id: '1',
        title: "Dinner at Mario's",
        amount: 1200,
        paidBy: 'You',
        splitAmong: ['You', 'Ansh', 'Sarah'],
        category: 'food',
        date: DateTime.now().subtract(const Duration(hours: 3))),
    ExpenseModel(
        id: '2',
        title: 'Uber to Airport',
        amount: 455,
        paidBy: 'Ansh',
        splitAmong: ['Ansh', 'Sarah'],
        category: 'transport',
        date: DateTime.now().subtract(const Duration(hours: 8))),
    ExpenseModel(
        id: '3',
        title: 'Hotel Stay — Night 1',
        amount: 3200,
        paidBy: 'Sarah',
        splitAmong: ['You', 'Ansh', 'Sarah', 'Riya'],
        category: 'stay',
        date: DateTime.now().subtract(const Duration(days: 1))),
    ExpenseModel(
        id: '4',
        title: 'Souvenirs & Gifts',
        amount: 750,
        paidBy: 'You',
        splitAmong: ['You', 'Riya'],
        category: 'other',
        date: DateTime.now().subtract(const Duration(days: 1, hours: 5))),
  ];

  /// Mock settlement logic — replace with real computed data from backend.
  /// Format: {'from': String, 'to': String, 'amount': double}
  final List<SettlementModel> _settlements = const [
    SettlementModel(from: 'You', to: 'Ansh', amount: 500),
    SettlementModel(from: 'Sarah', to: 'You', amount: 200),
    SettlementModel(from: 'Riya', to: 'You', amount: 375),
  ];

  // ── Helpers ───────────────────────────────────────────────────────────────
  double get _totalSpend =>
      _expenses.fold(0, (sum, e) => sum + e.amount);

  static const _categoryIcons = <String, IconData>{
    'food': Icons.restaurant_rounded,
    'transport': Icons.directions_car_rounded,
    'stay': Icons.hotel_rounded,
    'other': Icons.shopping_bag_outlined,
    'others': Icons.shopping_bag_outlined,
  };

  Color _categoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'food':
        return const Color(0xFFEA580C);
      case 'transport':
        return const Color(0xFF3B82F6);
      case 'stay':
        return const Color(0xFF8B5CF6);
      default:
        return kTeal;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _openAddExpense() {
    AddExpenseScreen.show(
      context,
      tripId: 1, // TODO: pass real trip id
      currentUserId: _currentUserId,
      currentUserName: _currentUserName,
      members: _members,
      onSaved: () => setState(() {}),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: kNavy,
      floatingActionButton: _buildFAB(),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: kTeal,
        backgroundColor: kNavy2,
        onRefresh: () async {
          // TODO: call real API
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            _buildTotalSpendCard(),
            const SizedBox(height: 20),
            _buildSettlementSection(),
            const SizedBox(height: 24),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: kNavy,
      elevation: 0,
      title: const Text('Trip Wallet',
          style: TextStyle(
              fontWeight: FontWeight.w800, color: kWhite, fontSize: 20)),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: kNavy2,
              borderRadius: BorderRadius.circular(kRadius12),
              border: Border.all(color: kWhite.withValues(alpha: 0.08)),
            ),
            child: const Icon(Icons.more_horiz_rounded,
                color: kWhite, size: 20),
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _openAddExpense,
      backgroundColor: kTeal,
      icon: const Icon(Icons.add_rounded, color: kWhite),
      label: const Text('Add Expense',
          style: TextStyle(
              color: kWhite, fontWeight: FontWeight.w700, fontSize: 14)),
      elevation: 6,
    );
  }

  // ─── Total Spend Card ──────────────────────────────────────────────────────
  Widget _buildTotalSpendCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2040), Color(0xFF0A1830)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kTeal.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: kTeal.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: kTeal, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('TOTAL TRIP SPEND',
                  style: TextStyle(
                      color: kSlate,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '₹${_totalSpend.toStringAsFixed(0)}',
            style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: kWhite,
                letterSpacing: -1),
          ),
          const SizedBox(height: 4),
          Text(
            '${_expenses.length} expenses recorded',
            style: TextStyle(color: kSlate.withValues(alpha: 0.7), fontSize: 13),
          ),
          const SizedBox(height: 20),
          // Mini breakdown bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: _buildCategoryBar(),
            ),
          ),
          const SizedBox(height: 10),
          _buildCategoryLegend(),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryBar() {
    final catTotals = <String, double>{};
    for (final e in _expenses) {
      catTotals[e.category] =
          (catTotals[e.category] ?? 0) + e.amount;
    }
    final total =
        catTotals.values.fold<double>(0, (a, b) => a + b);
    if (total == 0) return [];
    return catTotals.entries.map((entry) {
      return Expanded(
        flex: (entry.value / total * 100).round(),
        child: Container(
          height: 6,
          color: _categoryColor(entry.key),
        ),
      );
    }).toList();
  }

  Widget _buildCategoryLegend() {
    final catNames = {'food': 'Food', 'transport': 'Transport', 'stay': 'Stay', 'other': 'Others'};
    final catTotals = <String, double>{};
    for (final e in _expenses) {
      catTotals[e.category] =
          (catTotals[e.category] ?? 0) + e.amount;
    }
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: catTotals.entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                    color: _categoryColor(entry.key),
                    shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(
              '${catNames[entry.key] ?? entry.key} ₹${entry.value.toStringAsFixed(0)}',
              style: const TextStyle(color: kSlate, fontSize: 11),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ─── Settlement Section ────────────────────────────────────────────────────
  Widget _buildSettlementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Settlements',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kWhite)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: kTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${_settlements.length}',
                  style: const TextStyle(
                      color: kTeal,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._settlements.map((s) => _buildSettlementTile(s)),
      ],
    );
  }

  Widget _buildSettlementTile(SettlementModel s) {
    final isYouOwe = s.from == _currentUserName;
    final color = isYouOwe
        ? const Color(0xFFEF4444) // red
        : const Color(0xFF22C55E); // green
    final bgColor = isYouOwe
        ? const Color(0xFFEF4444).withValues(alpha: 0.08)
        : const Color(0xFF22C55E).withValues(alpha: 0.08);
    final icon = isYouOwe
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    final fromName = isYouOwe ? 'You' : s.from;
    final toName = isYouOwe ? s.to : 'you';
    final label = isYouOwe
        ? 'You owe ${s.to}'
        : '${s.from} owes you';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kNavy2,
        borderRadius: BorderRadius.circular(kRadius16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kWhite)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    _avatarBubble(fromName),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        color: kSlate.withValues(alpha: 0.6), size: 12),
                    const SizedBox(width: 4),
                    _avatarBubble(toName),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${s.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: color)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: color.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Text('Settle',
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarBubble(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: kNavy3, borderRadius: BorderRadius.circular(20)),
      child: Text(name,
          style: const TextStyle(
              color: kSlate, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }

  // ─── Recent Activity ───────────────────────────────────────────────────────
  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Activity',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kWhite)),
            Text('View All',
                style: TextStyle(
                    color: kTeal,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        ..._expenses.map((e) => _expenseItem(e)),
      ],
    );
  }

  Widget _expenseItem(ExpenseModel e) {
    final color = _categoryColor(e.category);
    final icon =
        _categoryIcons[e.category] ?? Icons.receipt_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kNavy2,
        borderRadius: BorderRadius.circular(kRadius16),
        border: Border.all(color: kWhite.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kWhite)),
                const SizedBox(height: 3),
                Text(
                  'Paid by ${e.paidBy} • ${e.splitAmong.length} members',
                  style: const TextStyle(fontSize: 11, color: kSlate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${e.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: kWhite)),
              const SizedBox(height: 3),
              Text(_timeAgo(e.date),
                  style: const TextStyle(
                      fontSize: 10, color: kSlate)),
            ],
          ),
        ],
      ),
    );
  }
}
