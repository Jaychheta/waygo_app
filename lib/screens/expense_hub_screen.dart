import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../services/trip_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/custom_button.dart';
import '../widgets/animated_card.dart';
import '../models/trip_model.dart';
import 'trip_chat_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PART 1 — ExpenseHubScreen: shows all user trips to pick from
// ─────────────────────────────────────────────────────────────────────────────

class ExpenseHubScreen extends StatefulWidget {
  const ExpenseHubScreen({super.key});

  @override
  State<ExpenseHubScreen> createState() => _ExpenseHubScreenState();
}

class _ExpenseHubScreenState extends State<ExpenseHubScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _authService = const AuthService();
  Future<List<TripModel>> _tripsFuture = Future.value([]);
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _tripsFuture = _fetchTrips();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _loadTrips();
    }
    _isInit = true;
  }

  Future<List<TripModel>> _fetchTrips() async {
    final userIdStr = await _authService.getUserId();
    if (userIdStr == null) return [];
    final userId = int.tryParse(userIdStr) ?? 0;
    final token = await _authService.getToken();
    return const TripService().getUserTrips(userId, token: token);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: kSurface,
      body: RefreshIndicator(
        color: const Color(0xFF00BFA5),
        backgroundColor: const Color(0xFF111111),
        onRefresh: () async {
          await _loadTrips();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            backgroundColor: kSurface,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: const Text(
                'Financials',
                style: TextStyle(color: kWhite, fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -1),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Track your global spending with precision.',
                    style: TextStyle(color: kWhite.withValues(alpha: 0.4), fontSize: 14),
                  ).animate().fadeIn(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          FutureBuilder<List<TripModel>>(
            future: _tripsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: kTeal))),
                );
              }
              final trips = snapshot.data ?? [];
              if (trips.isEmpty) {
                return SliverToBoxAdapter(child: _buildEmptyHub());
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final trip = trips[i];
                      return AnimatedCard(
                        index: i,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TripExpenseDetailScreen(
                                  tripId: trip.id,
                                  tripName: trip.name,
                                ),
                            ),
                          );
                          _loadTrips(); // Refresh trips when returning
                        },
                        child: _tripExpenseCard(trip),
                      );
                    },
                    childCount: trips.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      ),
    );
  }

  Widget _tripExpenseCard(TripModel trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: kTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded, color: kTeal),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.name,
                    style: const TextStyle(color: kWhite, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trip.location,
                    style: TextStyle(color: kWhite.withValues(alpha: 0.3), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: kWhite, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHub() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.payments_outlined, color: kWhite.withValues(alpha: 0.05), size: 100),
            const SizedBox(height: 16),
            Text('No active ledgers.', style: TextStyle(color: kWhite.withValues(alpha: 0.3))),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PART 2 — TripExpenseDetailScreen
// ─────────────────────────────────────────────────────────────────────────────

class TripExpenseDetailScreen extends StatefulWidget {
  final int tripId;
  final String tripName;

  const TripExpenseDetailScreen({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  @override
  State<TripExpenseDetailScreen> createState() => _TripExpenseDetailScreenState();
}

class _TripExpenseDetailScreenState extends State<TripExpenseDetailScreen> {
  final _tripService = const TripService();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  
  List<dynamic> _expenses = [];
  List<dynamic> _members = [];
  bool _isLoading = true;
  double _totalSpent = 0.0;
  String? _myId;

  final Map<String, IconData> _categoryIcons = {
    'Food': Icons.restaurant_rounded,
    'Transport': Icons.directions_bus_rounded,
    'Stay': Icons.hotel_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Others': Icons.receipt_long_rounded,
  };

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchExpenses() async {
    setState(() => _isLoading = true);
    final results = await _tripService.getTripExpenses(widget.tripId);
    final members = await _tripService.getTripMembers(widget.tripId);
    final myId = await const AuthService().getUserId();
    
    double total = 0.0;
    for (var e in results) {
      total += double.tryParse(e['amount'].toString()) ?? 0.0;
    }

    if (mounted) {
      setState(() {
        _myId = myId;
        _expenses = results;
        _members = members;
        _totalSpent = total;
        _isLoading = false;
      });
    }
  }

  void _showAddExpenseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddExpenseSheet(
        tripId: widget.tripId,
        onAdded: () {
          _fetchExpenses();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            backgroundColor: kSurface,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kWhite, size: 20),
            ),
            actions: [
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TripChatScreen(
                      tripId: widget.tripId,
                      tripName: widget.tripName,
                      members: _members,
                    ),
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: kTeal, size: 20),
              ),
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettlementScreen(
                      tripName: widget.tripName,
                      members: _members,
                      expenses: _expenses,
                    ),
                  ),
                ),
                icon: const Icon(Icons.balance_rounded, color: kTeal, size: 20),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _buildOrbSummary(),
              title: Text(
                widget.tripName,
                style: const TextStyle(color: kWhite, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5),
              ),
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
            ),
          ),

          if (_members.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                height: 80,
                padding: const EdgeInsets.only(top: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _members.length,
                  itemBuilder: (ctx, i) {
                    final m = _members[i];
                    final isIdMe = m['id']?.toString() == _myId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isIdMe ? kTeal : kWhite.withValues(alpha: 0.1),
                            child: Text(m['name'][0].toUpperCase(), style: TextStyle(color: isIdMe ? Colors.black : kWhite, fontWeight: FontWeight.w900, fontSize: 12)),
                          ),
                          const SizedBox(height: 4),
                          Text(isIdMe ? 'You' : m['name'].split(' ')[0], style: TextStyle(color: kWhite.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator(color: kTeal))),
            )
          else if (_expenses.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final expense = _expenses[i];
                    return _chatBubble(expense, i);
                  },
                  childCount: _expenses.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseSheet,
        backgroundColor: kTeal,
        label: const Text('Record', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
        icon: const Icon(Icons.add_rounded, color: Colors.black),
      ).animate().scale(delay: 500.ms),
    );
  }

  Widget _chatBubble(dynamic expense, int index) {
    final isMe = expense['user_id']?.toString() == _myId;
    final title = expense['title'] ?? 'Expense';
    final amount = double.tryParse(expense['amount'].toString()) ?? 0.0;
    final spender = expense['spender'] ?? 'Someone';
    final category = expense['category'] ?? 'Others';
    final date = expense['date'] != null ? expense['date'].toString().substring(11, 16) : 'Now';

    final bubble = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                spender,
                style: TextStyle(color: kTeal, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: kWhite.withValues(alpha: 0.1),
                  child: Text(spender[0].toUpperCase(), style: const TextStyle(color: kWhite, fontSize: 10, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: GlassContainer(
                  radius: 20,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_categoryIcons[category] ?? Icons.receipt_long_rounded, color: isMe ? kTeal : kWhite.withValues(alpha: 0.3), size: 14),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: const TextStyle(color: kWhite, fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.more_horiz_rounded, color: kWhite.withValues(alpha: 0.3), size: 14),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${amount.toStringAsFixed(0)}',
                            style: TextStyle(color: kTeal, fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            date,
                            style: TextStyle(color: kWhite.withValues(alpha: 0.2), fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isMe) const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: isMe ? 0.2 : -0.2);

    if (!isMe) return bubble;
    return GestureDetector(
      onLongPress: () => _showExpenseOptions(expense),
      child: bubble,
    );
  }

  void _showExpenseOptions(dynamic expense) {
    final title = expense['title'] ?? 'Expense';
    final amount = double.tryParse(expense['amount'].toString()) ?? 0.0;
    final category = expense['category'] ?? 'Others';
    final expenseId = int.tryParse(expense['id']?.toString() ?? '');
    if (expenseId == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: kWhite.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(_categoryIcons[category] ?? Icons.receipt_long_rounded, color: kTeal, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: kWhite, fontWeight: FontWeight.w800, fontSize: 15)),
                      Text('₹${amount.toStringAsFixed(0)} · $category',
                          style: TextStyle(color: kTeal.withValues(alpha: 0.8), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // EDIT
            _expenseOptionTile(
              icon: Icons.edit_rounded,
              label: 'Edit Expense',
              color: kTeal,
              onTap: () {
                Navigator.pop(ctx);
                _showEditExpenseSheet(expense);
              },
            ),
            const SizedBox(height: 12),
            // DELETE
            _expenseOptionTile(
              icon: Icons.delete_forever_rounded,
              label: 'Delete Expense',
              color: const Color(0xFFFF5B5B),
              onTap: () {
                Navigator.pop(ctx);
                _deleteExpense(expenseId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _expenseOptionTile({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteExpense(int expenseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Expense?', style: TextStyle(color: kWhite, fontWeight: FontWeight.w900)),
        content: const Text('This record will be permanently removed.', style: TextStyle(color: Colors.white60)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFFF5B5B), fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await _tripService.deleteExpense(expenseId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Expense deleted.' : 'Failed to delete.'),
      backgroundColor: ok ? const Color(0xFFFF5B5B) : Colors.red[900],
      behavior: SnackBarBehavior.floating,
    ));
    if (ok) _fetchExpenses();
  }

  void _showEditExpenseSheet(dynamic expense) {
    final expenseId = int.tryParse(expense['id']?.toString() ?? '');
    if (expenseId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditExpenseSheet(
        expenseId: expenseId,
        initialTitle: expense['title'] ?? '',
        initialAmount: double.tryParse(expense['amount'].toString()) ?? 0.0,
        initialCategory: expense['category'] ?? 'Others',
        onUpdated: _fetchExpenses,
      ),
    );
  }

  Widget _buildOrbSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: 0.75,
                  strokeWidth: 8,
                  color: kTeal,
                  backgroundColor: kWhite.withValues(alpha: 0.05),
                ),
              ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds),
              Column(
                children: [
                  Text(
                    'TOTAL',
                    style: TextStyle(color: kWhite.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 2),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    child: Text(
                      '₹${_totalSpent.toStringAsFixed(0)}',
                      style: const TextStyle(color: kWhite, fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            radius: 30,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_graph_rounded, color: kTeal, size: 14),
                const SizedBox(width: 8),
                Text(
                  'Within expected budget',
                  style: TextStyle(color: kWhite.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Icon(Icons.receipt_long_rounded, color: kWhite.withValues(alpha: 0.05), size: 100),
          const SizedBox(height: 16),
          Text('Cloud ledger is empty.', style: TextStyle(color: kWhite.withValues(alpha: 0.3))),
        ],
      ),
    );
  }
}

class _AddExpenseSheet extends StatefulWidget {
  final int tripId;
  final VoidCallback onAdded;
  const _AddExpenseSheet({required this.tripId, required this.onAdded});

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _selectedCat = 'Food';
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: GlassContainer(
        radius: 32,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Record',
              style: TextStyle(color: kWhite, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1),
            ),
            const SizedBox(height: 32),
            _sheetField('Description', _titleCtrl, Icons.edit_note_rounded),
            const SizedBox(height: 20),
            _sheetField('Amount', _amountCtrl, Icons.currency_rupee_rounded, keyboardType: TextInputType.number),
            const SizedBox(height: 32),
            
            Text(
              'CATEGORY',
              style: TextStyle(color: kWhite.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2),
            ),
            const SizedBox(height: 16),
            _buildCategoryPicker(),
            
            const SizedBox(height: 48),
            CustomButton(
              text: 'Save to Vault',
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sheetField(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(color: kWhite.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(color: kWhite, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: kTeal, size: 18),
            filled: true,
            fillColor: kWhite.withValues(alpha: 0.02),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: kWhite.withValues(alpha: 0.05))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: kWhite.withValues(alpha: 0.05))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kTeal)),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPicker() {
    final cats = ['Food', 'Transport', 'Stay', 'Shopping', 'Others'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cats.map((c) {
        final isSel = _selectedCat == c;
        return GestureDetector(
          onTap: () => setState(() => _selectedCat = c),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSel ? kTeal : kWhite.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSel ? kTeal : kWhite.withValues(alpha: 0.1)),
            ),
            child: Text(
              c,
              style: TextStyle(color: isSel ? kWhite : kWhite.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _submit() async {
    final t = _titleCtrl.text.trim();
    final a = double.tryParse(_amountCtrl.text) ?? 0.0;
    if (t.isEmpty || a <= 0) return;

    setState(() => _isSubmitting = true);
    final success = await const TripService().addExpense(
      tripId: widget.tripId,
      title: t,
      amount: a,
      category: _selectedCat,
    );
    if (success) {
      if (mounted) {
        widget.onAdded();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense added successfully!'), backgroundColor: kTeal, behavior: SnackBarBehavior.floating),
        );
      }
    } else {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add expense. Check connection.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}

class _EditExpenseSheet extends StatefulWidget {
  final int expenseId;
  final String initialTitle;
  final double initialAmount;
  final String initialCategory;
  final VoidCallback onUpdated;
  const _EditExpenseSheet({
    required this.expenseId,
    required this.initialTitle,
    required this.initialAmount,
    required this.initialCategory,
    required this.onUpdated,
  });

  @override
  State<_EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends State<_EditExpenseSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late String _selectedCat;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle);
    _amountCtrl = TextEditingController(text: widget.initialAmount.toStringAsFixed(0));
    _selectedCat = widget.initialCategory;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: GlassContainer(
        radius: 32,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Record',
              style: TextStyle(color: kWhite, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1),
            ),
            const SizedBox(height: 32),
            _field('Description', _titleCtrl, Icons.edit_note_rounded),
            const SizedBox(height: 20),
            _field('Amount', _amountCtrl, Icons.currency_rupee_rounded, keyboardType: TextInputType.number),
            const SizedBox(height: 32),
            Text(
              'CATEGORY',
              style: TextStyle(color: kWhite.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2),
            ),
            const SizedBox(height: 16),
            _buildCategoryPicker(),
            const SizedBox(height: 48),
            CustomButton(
              text: 'Save Changes',
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(color: kWhite.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(color: kWhite, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: kTeal, size: 18),
            filled: true,
            fillColor: kWhite.withValues(alpha: 0.02),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: kWhite.withValues(alpha: 0.05))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: kWhite.withValues(alpha: 0.05))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kTeal)),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPicker() {
    final cats = ['Food', 'Transport', 'Stay', 'Shopping', 'Others'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cats.map((c) {
        final isSel = _selectedCat == c;
        return GestureDetector(
          onTap: () => setState(() => _selectedCat = c),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSel ? kTeal : kWhite.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSel ? kTeal : kWhite.withValues(alpha: 0.1)),
            ),
            child: Text(
              c,
              style: TextStyle(color: isSel ? kWhite : kWhite.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _submit() async {
    final t = _titleCtrl.text.trim();
    final a = double.tryParse(_amountCtrl.text) ?? 0.0;
    if (t.isEmpty || a <= 0) return;
    setState(() => _isSubmitting = true);
    final ok = await const TripService().updateExpense(
      expenseId: widget.expenseId,
      title: t,
      amount: a,
      category: _selectedCat,
    );
    if (ok) {
      if (mounted) {
        widget.onUpdated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense updated!'), backgroundColor: kTeal, behavior: SnackBarBehavior.floating),
        );
      }
    } else {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}

class SettlementScreen extends StatelessWidget {
  final String tripName;
  final List<dynamic> members;
  final List<dynamic> expenses;

  const SettlementScreen({super.key, required this.tripName, required this.members, required this.expenses});

  @override
  Widget build(BuildContext context) {
    // 1. Calculate each person's total spending
    final Map<int, double> spendingMap = {};
    for (var m in members) {
      final id = int.tryParse(m['id'].toString()) ?? 0;
      spendingMap[id] = 0.0;
    }
    
    double totalTripSpent = 0.0;
    for (var e in expenses) {
      final amt = double.tryParse(e['amount'].toString()) ?? 0.0;
      final uid = int.tryParse(e['user_id']?.toString() ?? '');
      if (uid != null && spendingMap.containsKey(uid)) {
        spendingMap[uid] = (spendingMap[uid] ?? 0.0) + amt;
      }
      totalTripSpent += amt;
    }

    final share = members.isEmpty ? 0.0 : totalTripSpent / members.length;
    final List<Map<String, dynamic>> balances = members.map((m) {
      final id = int.tryParse(m['id'].toString()) ?? 0;
      final spentByMe = spendingMap[id] ?? 0.0;
      return {
        'name': m['name'],
        'id': id,
        'balance': spentByMe - share,
      };
    }).toList();

    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurface,
        leading: IconButton(icon: const Icon(Icons.close_rounded, color: kWhite), onPressed: () => Navigator.pop(context)),
        elevation: 0,
        title: const Text('Who owes what?', style: TextStyle(color: kWhite, fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _topTotal(totalTripSpent),
            const SizedBox(height: 32),
            ...balances.map((b) => _simpleMemberCard(b)),
            const SizedBox(height: 40),
            if (totalTripSpent > 0)
              Text(
                'Each person\'s share: ₹${share.toStringAsFixed(0)}',
                style: TextStyle(color: kWhite.withValues(alpha: 0.2), fontSize: 12, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  Widget _topTotal(double total) {
    return Column(
      children: [
        Text('TRIP TOTAL', style: TextStyle(color: kWhite.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text(
          '₹${total.toStringAsFixed(0)}',
          style: const TextStyle(color: kTeal, fontSize: 42, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _simpleMemberCard(Map<String, dynamic> b) {
    final balance = b['balance'] as double;
    final isReceiver = balance > 0.1;
    final isPayer = balance < -0.1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        radius: 20,
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isReceiver ? kTeal.withValues(alpha: 0.1) : (isPayer ? kDanger.withValues(alpha: 0.1) : kWhite.withValues(alpha: 0.05)),
              child: Text(b['name'][0].toUpperCase(), style: TextStyle(color: isReceiver ? kTeal : (isPayer ? kDanger : kWhite), fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b['name'], style: const TextStyle(color: kWhite, fontWeight: FontWeight.w900, fontSize: 16)),
                  Text(
                    !isReceiver && !isPayer ? 'All settled' : (isReceiver ? 'To receive' : 'To give'),
                    style: TextStyle(color: kWhite.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Text(
              '₹${balance.abs().toStringAsFixed(0)}',
              style: TextStyle(
                color: isReceiver ? kTeal : (isPayer ? kDanger : kWhite.withValues(alpha: 0.2)),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
