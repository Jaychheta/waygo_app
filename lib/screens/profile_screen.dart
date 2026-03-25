import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:waygo_app/config/app_theme.dart';
import 'package:waygo_app/screens/login_screen.dart';
import 'package:waygo_app/services/auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProfileScreen — Dynamic User Profile Settings
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _pushNotifications = true;
  bool _twoFactorAuth = true;
  bool _isLoading = true;

  String _userName = '';
  String _userEmail = '';

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  final _authService = const AuthService();

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadUserData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  /// Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    final name = await _authService.getUserName();
    final email = await _authService.getUserEmail();
    if (!mounted) return;
    setState(() {
      _userName = name;
      _userEmail = email;
      _isLoading = false;
    });
    _fadeCtrl.forward();
  }

  /// Get first 2 initials from the user's name
  String get _initials {
    if (_userName.isEmpty) return '?';
    final parts = _userName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Calculate "Traveler since" from created_at (or fallback to current month/year)
  String get _travelerSince {
    // We could store created_at in SharedPreferences too, but for now
    // use a friendly fallback
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return 'Traveler since ${months[now.month - 1]} ${now.year}';
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kNavy2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out',
            style: TextStyle(
                color: kWhite, fontWeight: FontWeight.w800, fontSize: 18)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: kSlate, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: kSlate, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Log Out',
                style: TextStyle(
                    color: Colors.red.shade400, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.clearToken();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (ctx, animation, _) =>
              FadeTransition(opacity: animation, child: const LoginScreen()),
        ),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kNavy,
        body: Center(
          child: CircularProgressIndicator(color: kTeal, strokeWidth: 2.5),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: kNavy2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kWhite.withOpacity(0.15)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: kWhite, size: 16),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Profile Settings',
          style: TextStyle(
            color: kWhite,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () {},
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kNavy2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kWhite.withOpacity(0.15)),
                ),
                child: const Icon(Icons.more_horiz_rounded,
                    color: kSlate, size: 18),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 28),

              // ── PERSONAL INFORMATION ────────────────────────────────
              _buildSection(
                title: 'PERSONAL INFORMATION',
                children: [
                  _ProfileTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Full Name',
                    subtitle: _userName.isNotEmpty ? _userName : 'Not set',
                  ),
                  _divider(),
                  _ProfileTile(
                    icon: Icons.email_outlined,
                    title: 'Email Address',
                    subtitle:
                        _userEmail.isNotEmpty ? _userEmail : 'Not available',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── SECURITY & PRIVACY ─────────────────────────────────
              _buildSection(
                title: 'SECURITY & PRIVACY',
                children: [
                  _ProfileTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Change Password',
                    trailing: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: kWhite.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chevron_right_rounded,
                          color: kSlate, size: 20),
                    ),
                    onTap: () {},
                  ),
                  _divider(),
                  _ProfileTile(
                    icon: Icons.security_rounded,
                    title: 'Two-Factor Authentication',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _twoFactorAuth
                            ? const Color(0xFF059669).withOpacity(0.15)
                            : Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _twoFactorAuth
                              ? const Color(0xFF059669).withOpacity(0.15)
                              : Colors.red.withOpacity(0.15),
                        ),
                      ),
                      child: Text(
                        _twoFactorAuth ? 'ON' : 'OFF',
                        style: TextStyle(
                          color: _twoFactorAuth
                              ? const Color(0xFF34D399)
                              : Colors.red.shade300,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    onTap: () =>
                        setState(() => _twoFactorAuth = !_twoFactorAuth),
                  ),
                  _divider(),
                  _ProfileTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    trailing: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: kWhite.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chevron_right_rounded,
                          color: kSlate, size: 20),
                    ),
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── PREFERENCES ────────────────────────────────────────
              _buildSection(
                title: 'PREFERENCES',
                children: [
                  _ProfileTile(
                    icon: Icons.notifications_outlined,
                    title: 'Push Notifications',
                    trailing: Transform.scale(
                      scale: 0.8,
                      child: CupertinoSwitch(
                        value: _pushNotifications,
                        activeTrackColor: kTeal,
                        onChanged: (v) =>
                            setState(() => _pushNotifications = v),
                      ),
                    ),
                  ),
                  _divider(),
                  _ProfileTile(
                    icon: Icons.language_rounded,
                    title: 'Language',
                    subtitle: 'English',
                    trailing: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: kWhite.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chevron_right_rounded,
                          color: kSlate, size: 20),
                    ),
                  ),
                  _divider(),
                  _ProfileTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kTeal,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: kTeal.withOpacity(0.15)),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: kTeal,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _buildLogoutButton(),
              const SizedBox(height: 24),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Profile Header ──────────────────────────────────────────────────────────
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kNavy2, kNavy3.withOpacity(0.15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kWhite.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with dynamic initials + camera icon
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: kTealGradient,
                  boxShadow: [
                    BoxShadow(
                      color: kTeal.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: kNavy,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: CircleAvatar(
                      backgroundColor: kNavy3,
                      child: Text(
                        _initials,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: kWhite,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                    border: Border.all(color: kNavy2, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color(0xFF3B82F6).withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: kWhite, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dynamic Name
          Text(
            _userName.isNotEmpty ? _userName : 'Traveler',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: kWhite,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),

          // Dynamic subtitle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.explore_rounded,
                  color: kTeal.withOpacity(0.15), size: 14),
              const SizedBox(width: 6),
              Text(
                _travelerSince,
                style: TextStyle(
                  fontSize: 13,
                  color: kSlate,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Edit Profile button
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_rounded, color: kWhite, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: kWhite,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Builder ─────────────────────────────────────────────────────────
  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: kTeal,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: kNavy2,
            borderRadius: BorderRadius.circular(kRadius16),
            border: Border.all(color: kWhite.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  // ── Divider ─────────────────────────────────────────────────────────────────
  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: kWhite.withOpacity(0.15)),
    );
  }

  // ── Logout Button ───────────────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(kRadius16),
          border: Border.all(color: Colors.red.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 20),
            const SizedBox(width: 10),
            Text(
              'Log Out',
              style: TextStyle(
                color: Colors.red.shade400,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Footer ──────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: kWhite.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'WAYGO APP V2.4.1 (STABLE)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: kSlate,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Made with ❤️ for Travelers',
          style: TextStyle(
            fontSize: 11,
            color: kSlate,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Profile Tile Widget
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kRadius16),
      splashColor: kTeal.withOpacity(0.15),
      highlightColor: kTeal.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kTeal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: kWhite, size: 20),
            ),
            const SizedBox(width: 14),

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: kWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: kSlate,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Trailing widget
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
