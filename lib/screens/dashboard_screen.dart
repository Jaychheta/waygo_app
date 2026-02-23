import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waygo_app/config/app_theme.dart';
import 'package:waygo_app/screens/ai_planner_screen.dart';
import 'package:waygo_app/screens/expense_hub_screen.dart';
import 'package:waygo_app/screens/home_screen.dart';
import 'package:waygo_app/screens/login_screen.dart';
import 'package:waygo_app/screens/memory_vault_screen.dart';
import 'package:waygo_app/services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.userName = 'Traveler'});
  static const String routeName = '/dashboard';
  final String userName;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(userName: widget.userName),
      const AiPlannerScreen(),
      const ExpenseHubScreen(),
      const MemoryVaultScreen(),
    ];

    // Make status bar transparent
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  Future<void> _logout() async {
    await const AuthService().clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (ctx, animation, _) => FadeTransition(opacity: animation, child: const LoginScreen()),
      ),
      (_) => false,
    );
  }

  // ─── Bottom nav items ────────────────────────────────────────────────────
  static const _navItems = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.auto_awesome_rounded, label: 'Planner'),
    _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Expenses'),
    _NavItem(icon: Icons.photo_library_rounded, label: 'Memories'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      // Transparent AppBar holds the logout action so _logout() is referenced
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 0,
              actions: [
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, color: kSlate, size: 0), // hidden; actual logout trigger lives in HomeScreen
                ),
              ],
            )
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C1B35),
        border: Border(top: BorderSide(color: kWhite.withValues(alpha: 0.07), width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final selected = i == _selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    decoration: selected
                        ? BoxDecoration(
                            color: kTeal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(kRadius12),
                          )
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          scale: selected ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 220),
                          child: Icon(item.icon, color: selected ? kTeal : kSlate, size: 24),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          style: TextStyle(
                            color: selected ? kTeal : kSlate,
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}