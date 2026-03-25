import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:waygo_app/config/api_config.dart';
import 'package:waygo_app/config/app_theme.dart';
import 'package:waygo_app/services/auth_service.dart';
import 'package:waygo_app/services/trip_service.dart';

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
  Future<List<dynamic>> _tripsFuture = Future.value([]);

  @override
  void initState() {
    super.initState();
    _tripsFuture = _fetchTrips();
  }

  Future<List<dynamic>> _fetchTrips() async {
    final userIdStr = await _authService.getUserId();
    if (userIdStr == null) {
      // If no user ID, we can't fetch trips.
      return [];
    }
    final userId = int.tryParse(userIdStr);
    if (userId == null) return [];
    
    final token = await _authService.getToken();
    return TripService().getUserTrips(userId, token: token);
  }

  Future<void> _refreshTrips() async {
    setState(() {
      _tripsFuture = _fetchTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: kNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Expense Hub',
          style: TextStyle(color: kWhite, fontWeight: FontWeight.w800, fontSize: 22),
        ),
        actions: [
          IconButton(
            onPressed: _refreshTrips,
            icon: const Icon(Icons.refresh_rounded, color: kWhite),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTrips,
        color: kTeal,
        backgroundColor: kNavy2,
        child: FutureBuilder<List<dynamic>>(
        future: _tripsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kTeal));
          }
          final trips = snapshot.data ?? [];
          if (trips.isEmpty) {
            return const Center(child: Text('No trips found', style: TextStyle(color: kSlate)));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: trips.length,
            itemBuilder: (_, i) {
              final trip = trips[i] as Map<String, dynamic>;
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => TripExpenseDetailScreen(
                      tripId: (trip['id'] as num).toInt(),
                      tripName: trip['name'] ?? 'Trip',
                    ),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kNavy2,
                    borderRadius: BorderRadius.circular(kRadius),
                    border: Border.all(color: kWhite.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: kTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.wallet_rounded, color: kTeal),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(trip['name'] ?? '', style: const TextStyle(color: kWhite, fontWeight: FontWeight.w700)),
                            Text(trip['location'] ?? '', style: const TextStyle(color: kSlate, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: kSlate),
                    ],
                  ),
                ),
              );
            },
            );
          },
        ),
      ),
    );
  }
}

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
  String _selectedCategory = 'Food';
  final List<String> _categories = ['Food', 'Transport', 'Stay', 'Shopping', 'Others'];

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

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: kNavy2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Expense', style: TextStyle(color: kWhite, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: kWhite),
                  decoration: InputDecoration(
                    hintText: 'Description (e.g., Dinner)',
                    hintStyle: const TextStyle(color: kSlate),
                    filled: true,
                    fillColor: kNavy.withOpacity(0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: kWhite),
                  decoration: InputDecoration(
                    hintText: 'Amount (e.g., 25.50)',
                    hintStyle: const TextStyle(color: kSlate),
                    filled: true,
                    fillColor: kNavy.withOpacity(0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Category', style: TextStyle(color: kSlate, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() => _selectedCategory = cat);
                        setState(() => _selectedCategory = cat);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? kTeal : kNavy.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? kTeal : kWhite.withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_categoryIcons[cat], color: isSelected ? kWhite : kSlate, size: 14),
                            const SizedBox(width: 6),
                            Text(cat, style: TextStyle(color: isSelected ? kWhite : kSlate, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: kSlate))),
            ElevatedButton(
              onPressed: () async {
                final title = _titleController.text.trim();
                final amount = double.tryParse(_amountController.text) ?? 0.0;
                
                if (title.isNotEmpty && amount > 0) {
                  final success = await _tripService.addExpense(
                    tripId: widget.tripId,
                    title: title,
                    amount: amount,
                    category: _selectedCategory,
                  );
                  if (success && mounted) {
                    _titleController.clear();
                    _amountController.clear();
                    Navigator.pop(ctx);
                    _fetchExpenses();
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: kTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Add', style: TextStyle(color: kWhite, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: kWhite.withOpacity(0.05), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_rounded, color: kWhite, size: 20),
          ),
        ),
        title: Text(widget.tripName, style: const TextStyle(color: kWhite, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            onPressed: _fetchExpenses,
            icon: const Icon(Icons.refresh_rounded, color: kSlate),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: kTeal))
        : Column(
            children: [
              _buildSummaryCard(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    const Text('History', style: TextStyle(color: kWhite, fontSize: 18, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text('${_expenses.length} Records', style: const TextStyle(color: kSlate, fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: _expenses.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: _expenses.length,
                      itemBuilder: (_, i) => _buildExpenseTile(_expenses[i]),
                    ),
              ),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        backgroundColor: kTeal,
        child: const Icon(Icons.add_rounded, color: kWhite, size: 30),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: kTealGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: kTeal.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Spent', style: TextStyle(color: kWhite.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('\$${_totalSpent.toStringAsFixed(2)}', style: const TextStyle(color: kWhite, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: kWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.analytics_rounded, color: kWhite, size: 16),
                const SizedBox(width: 6),
                Text('Trip Budget Tracking', style: const TextStyle(color: kWhite, fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTile(dynamic expense) {
    final title = expense['title'] ?? 'Expense';
    final amount = double.tryParse(expense['amount'].toString()) ?? 0.0;
    final category = expense['category'] ?? 'Others';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kNavy2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kWhite.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: kTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_categoryIcons[category] ?? Icons.receipt_long_rounded, color: kTeal, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: kWhite, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(category, style: const TextStyle(color: kTeal, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(width: 4, height: 4, decoration: const BoxDecoration(color: kSlate, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(expense['date'] != null ? expense['date'].toString().substring(0, 10) : 'Today', style: const TextStyle(color: kSlate, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Text('\$${amount.toStringAsFixed(2)}', style: const TextStyle(color: kWhite, fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_outlined, color: kSlate.withOpacity(0.3), size: 60),
          const SizedBox(height: 16),
          const Text('No expenses recorded yet', style: TextStyle(color: kSlate, fontSize: 14)),
        ],
      ),
    );
  }
}
