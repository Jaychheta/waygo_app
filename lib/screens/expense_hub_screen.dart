import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../services/trip_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/custom_button.dart';
import '../widgets/animated_card.dart';
import '../models/trip_model.dart';

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
  bool _isLoading = true;
  double _totalSpent = 0.0;

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
    
    double total = 0.0;
    for (var e in results) {
      total += double.tryParse(e['amount'].toString()) ?? 0.0;
    }

    if (mounted) {
      setState(() {
        _expenses = results;
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
          Navigator.pop(ctx);
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
            expandedHeight: 320,
            backgroundColor: kSurface,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kWhite, size: 20),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildOrbSummary(),
              title: Text(
                widget.tripName,
                style: const TextStyle(color: kWhite, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -1),
              ),
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final expense = _expenses[i];
                    return AnimatedCard(
                      index: i,
                      child: _expenseTile(expense),
                    );
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
        label: const Text('Add Expense', style: TextStyle(color: kWhite, fontWeight: FontWeight.w800, letterSpacing: 1)),
        icon: const Icon(Icons.add_rounded, color: kWhite),
      ).animate().scale(delay: 500.ms),
    );
  }

  Widget _buildOrbSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: 0.75, // Sample budget progress
                  strokeWidth: 10,
                  color: kTeal,
                  backgroundColor: kWhite.withValues(alpha: 0.05),
                ),
              ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds),
              Column(
                children: [
                  Text(
                    'TOTAL',
                    style: TextStyle(color: kWhite.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${_totalSpent.toStringAsFixed(0)}',
                    style: const TextStyle(color: kWhite, fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            radius: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_graph_rounded, color: kTeal, size: 16),
                const SizedBox(width: 10),
                Text(
                  'Within expected budget',
                  style: TextStyle(color: kWhite.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _expenseTile(dynamic expense) {
    final title = expense['title'] ?? 'Expense';
    final amount = double.tryParse(expense['amount'].toString()) ?? 0.0;
    final category = expense['category'] ?? 'Others';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: kWhite.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12)),
              child: Icon(_categoryIcons[category] ?? Icons.receipt_long_rounded, color: kTeal, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: kWhite, fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(category.toUpperCase(), style: const TextStyle(color: kTeal, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const SizedBox(width: 8),
                      Container(width: 3, height: 3, decoration: BoxDecoration(color: kWhite.withValues(alpha: 0.1), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(
                        expense['date'] != null ? expense['date'].toString().substring(0, 10) : 'Today', 
                        style: TextStyle(color: kWhite.withValues(alpha: 0.2), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text('\$${amount.toStringAsFixed(2)}', style: const TextStyle(color: kWhite, fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
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
            _sheetField('Amount', _amountCtrl, Icons.attach_money_rounded, keyboardType: TextInputType.number),
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
      widget.onAdded();
    } else {
      setState(() => _isSubmitting = false);
    }
  }
}
