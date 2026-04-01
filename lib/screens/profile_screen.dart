import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/animated_card.dart';
import '../widgets/custom_button.dart';
import '../services/trip_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _pushNotifications = true;
  bool _isLoading = true;
  String _userName = '';
  String _userEmail = '';
  int _tripsCount = 0;
  int _daysTraveled = 0;
  int _placesVisited = 0;
  final _authService = const AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await _authService.getUserName();
    final email = await _authService.getUserEmail();
    
    final userIdStr = await _authService.getUserId();
    if (userIdStr != null) {
      final userId = int.tryParse(userIdStr) ?? 0;
      final token = await _authService.getToken();
      final trips = await const TripService().getUserTrips(userId, token: token);
      
      int days = 0;
      final places = <String>{};
      for (var t in trips) {
        days += t.endDate.difference(t.startDate).inDays;
        places.add(t.location.toLowerCase());
      }
      _tripsCount = trips.length;
      _daysTraveled = trips.isEmpty ? 0 : (days > 0 ? days : 1);
      _placesVisited = places.length;
    }

    if (mounted) {
      setState(() {
        _userName = name;
        _userEmail = email;
        _isLoading = false;
      });
    }
  }

  String get _initials {
    if (_userName.isEmpty) return 'W';
    final parts = _userName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0].substring(0, 1).toUpperCase();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: kWhite.withValues(alpha: 0.1))),
        title: const Text('Sign Out', style: TextStyle(color: kWhite, fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to end your luxury session?', style: TextStyle(color: kWhite.withValues(alpha: 0.5))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: kSlate))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: kTeal, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.clearToken();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  String _appearance = 'Dark Gold (Active)';
  Color _currentSurface = kSurface;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(backgroundColor: _currentSurface, body: const Center(child: CircularProgressIndicator(color: kTeal)));

    return Scaffold(
      backgroundColor: _currentSurface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildStatsRow(),
                  const SizedBox(height: 40),
                  _buildSectionHeader('PREFERENCES'),
                  const SizedBox(height: 16),
                  _profileTile(Icons.notifications_active_rounded, 'Push Notifications', trailing: _buildSwitch()),
                  _profileTile(Icons.language_rounded, 'Language', subtitle: 'English (US)', onTap: () => _showComingSoon('Language selection')),
                  _profileTile(Icons.dark_mode_rounded, 'Appearance', subtitle: _appearance, onTap: () {
                    setState(() {
                      if (_appearance.contains('Dark')) {
                        _appearance = 'Midnight Blue (Active)';
                        _currentSurface = kNavy;
                      } else {
                        _appearance = 'Dark Gold (Active)';
                        _currentSurface = kSurface;
                      }
                    });
                  }),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader('ACCOUNT'),
                  const SizedBox(height: 16),
                  _profileTile(Icons.security_rounded, 'Security & Privacy', onTap: () => _showComingSoon('Security')),
                  _profileTile(Icons.help_center_rounded, 'Support Center', onTap: () => _showComingSoon('Support')),
                  
                  const SizedBox(height: 48),
                  CustomButton(
                    text: 'Sign Out',
                    variant: ButtonVariant.danger,
                    onPressed: _logout,
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      stretch: true,
      backgroundColor: _currentSurface,
      leading: Navigator.of(context).canPop() 
        ? IconButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).maybePop();
              }
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kWhite, size: 20),
          )
        : null,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.center,
          children: [
            // Decorative background elements
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(shape: BoxShape.circle, color: kTeal.withValues(alpha: 0.03)),
              ).animate().scale(duration: 2.seconds, curve: Curves.easeInOut),
            ),
            
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                _buildAvatar(),
                const SizedBox(height: 20),
                Text(
                  _userName.toUpperCase(),
                  style: const TextStyle(color: kWhite, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 4),
                Text(
                  _userEmail,
                  style: TextStyle(color: kWhite.withValues(alpha: 0.3), fontSize: 13, fontWeight: FontWeight.w500),
                ).animate().fadeIn(delay: 450.ms),
                const SizedBox(height: 16),
                _buildBadge(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: kTeal.withValues(alpha: 0.2), width: 2),
            boxShadow: [
              BoxShadow(color: kTeal.withValues(alpha: 0.15), blurRadius: 40, spreadRadius: 5),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: kTeal.withValues(alpha: 0.1),
              child: Text(
                _initials,
                style: const TextStyle(color: kTeal, fontSize: 36, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: kTeal, shape: BoxShape.circle),
          child: const Icon(Icons.camera_alt_rounded, color: kWhite, size: 14),
        ).animate().scale(delay: 600.ms),
      ],
    );
  }

  Widget _buildBadge() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      radius: 40,
      opacity: 0.1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: kTeal, size: 14),
          const SizedBox(width: 8),
          const Text(
            'ELITE MEMBER',
            style: TextStyle(color: kTeal, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms);
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statItem('$_tripsCount', 'TRIPS'),
        _statItem('$_placesVisited', 'DESTINATIONS'),
        _statItem('$_daysTraveled', 'DAYS TRAVELED'),
      ],
    ).animate().fadeIn(delay: 1.seconds);
  }

  Widget _statItem(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(color: kWhite, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: kWhite.withValues(alpha: 0.2), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
      ],
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature settings will be available in the next update.', style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: kTeal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(color: kWhite.withValues(alpha: 0.2), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2),
      ),
    );
  }

  Widget _profileTile(IconData icon, String title, {String? subtitle, Widget? trailing, VoidCallback? onTap}) {
    return AnimatedCard(
      onTap: onTap ?? () => _showComingSoon(title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: kWhite.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: kTeal, size: 18),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: kWhite, fontWeight: FontWeight.w800, fontSize: 15)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: kWhite.withValues(alpha: 0.3), fontSize: 12)),
                    ],
                  ],
                ),
              ),
              trailing ?? const Icon(Icons.arrow_forward_ios_rounded, color: kWhite, size: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitch() {
    return Transform.scale(
      scale: 0.8,
      child: CupertinoSwitch(
        value: _pushNotifications,
        activeTrackColor: kTeal,
        onChanged: (v) => setState(() => _pushNotifications = v),
      ),
    );
  }
}
