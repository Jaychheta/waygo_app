import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import 'home_screen.dart';
import 'ai_planner_screen.dart';
import 'expense_hub_screen.dart';
import 'memory_vault_screen.dart';
import 'profile_screen.dart';
import '../widgets/glass_container.dart';

class DashboardScreen extends StatefulWidget {
  final String? userName;
  const DashboardScreen({super.key, this.userName});

  static const String routeName = '/dashboard';

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(userName: widget.userName ?? 'Traveler'),
      const AiPlannerScreen(),
      const ExpenseHubScreen(),
      const MemoryVaultScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: kSurface,
      extendBody: true,
      body: AnimatedSwitcher(
        duration: 500.ms,
        child: screens[_currentIndex],
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation.drive(Tween(begin: 0.98, end: 1.0)),
              child: child,
            ),
          );
        },
      ),
      bottomNavigationBar: _buildLuxuryNav(),
    );
  }

  Widget _buildLuxuryNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: GlassContainer(
        height: 72,
        radius: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.grid_view_rounded, 'Home'),
            _navItem(1, Icons.auto_awesome_rounded, 'Plan'),
            _navItem(2, Icons.account_balance_wallet_rounded, 'Cash'),
            _navItem(3, Icons.camera_rounded, 'Vault'),
            _navItem(4, Icons.person_rounded, 'Self'),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 1.seconds).slideY(begin: 0.2, end: 0);
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          HapticFeedback.lightImpact();
          setState(() => _currentIndex = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: 400.ms,
        curve: Curves.easeOutBack,
        width: isSelected ? 80 : 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? kTeal.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? kTeal : kWhite.withValues(alpha: 0.3),
              size: 22,
            ).animate(target: isSelected ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
            if (isSelected)
              Text(
                label.toUpperCase(),
                style: const TextStyle(color: kTeal, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ).animate().fadeIn(delay: 100.ms),
          ],
        ),
      ),
    );
  }
}
