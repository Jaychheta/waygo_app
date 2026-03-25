import 'package:flutter/material.dart';
import 'package:waygo_app/config/app_theme.dart';
import 'package:waygo_app/screens/home_screen.dart';
import 'package:waygo_app/screens/ai_planner_screen.dart';
import 'package:waygo_app/screens/expense_hub_screen.dart';
import 'package:waygo_app/screens/memory_vault_screen.dart';
import 'package:waygo_app/screens/profile_screen.dart';
import 'package:waygo_app/services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  final String? userName;
  const DashboardScreen({super.key, this.userName});

  static const String routeName = '/dashboard';

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String _displayName = 'Traveler';
  final _authService = const AuthService();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _displayName = widget.userName ?? 'Traveler';
    if (widget.userName == null) {
      _loadUserName();
    }
  }

  Future<void> _loadUserName() async {
    final name = await _authService.getUserName();
    if (mounted) setState(() => _displayName = name);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(userName: _displayName),
      const AiPlannerScreen(),
      const ExpenseHubScreen(),
      const MemoryVaultScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: kNavy,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: kNavy2,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.transparent,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'AI Plan'),
          BottomNavigationBarItem(icon: Icon(Icons.wallet_rounded), label: 'Expense'),
          BottomNavigationBarItem(icon: Icon(Icons.photo_library_rounded), label: 'Vault'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
