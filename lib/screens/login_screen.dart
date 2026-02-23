import 'package:flutter/material.dart';
import 'package:waygo_app/config/app_theme.dart';
import 'package:waygo_app/screens/register_screen.dart';
import 'package:waygo_app/screens/dashboard_screen.dart';
import 'package:waygo_app/services/auth_service.dart';
import 'package:waygo_app/widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static const String routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authService = const AuthService();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    final result = await _authService.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red.shade800,
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            DashboardScreen(userName: result.user?.name ?? 'Traveler'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Full-screen deep navy gradient — no card
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF040F1E), Color(0xFF061026), Color(0xFF071530)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 56),

                  // ── Circular icon ──────────────────────────────────────
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0D2B1E),
                        border: Border.all(
                          color: kTeal.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.flight_takeoff_rounded,
                        color: kTeal,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Title ──────────────────────────────────────────────
                  const Center(
                    child: Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: kWhite,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Please enter your details to sign in.',
                      style: TextStyle(color: kSlate, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Email ──────────────────────────────────────────────
                  _fieldLabel('Email'),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: _emailCtrl,
                    hint: 'name@example.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if ((v?.trim() ?? '').isEmpty) return 'Email required';
                      if (!v!.contains('@')) return 'Invalid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Password ───────────────────────────────────────────
                  _fieldLabel('Password'),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: _passwordCtrl,
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscure,
                    validator: (v) =>
                        (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: kSlate,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),

                  // ── Forgot password ────────────────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.only(top: 10),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: kTeal,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Log In button ──────────────────────────────────────
                  CustomButton(
                    text: 'Log In',
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 28),

                  // ── Or continue with ───────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                          child: Divider(color: kWhite.withValues(alpha: 0.1))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'Or continue with',
                          style: TextStyle(
                              color: kSlate.withValues(alpha: 0.8),
                              fontSize: 12),
                        ),
                      ),
                      Expanded(
                          child: Divider(color: kWhite.withValues(alpha: 0.1))),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Social buttons — pill shaped, full row ─────────────
                  Row(
                    children: [
                      Expanded(child: _socialBtn(icon: Icons.g_mobiledata_rounded, label: 'Google', iconColor: const Color(0xFFEA4335))),
                      const SizedBox(width: 14),
                      Expanded(child: _socialBtn(icon: Icons.apple_rounded, label: 'Apple', iconColor: kWhite)),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // ── Register link ──────────────────────────────────────
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Don't have an account?  ",
                          style: TextStyle(color: kSlate, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => const RegisterScreen()),
                          ),
                          child: const Text(
                            'Register',
                            style: TextStyle(
                              color: kTeal,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: kWhite,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: kWhite, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kSlate),
        prefixIcon: Icon(icon, color: kSlate, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF0C1E2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(color: kWhite.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: kTeal, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  Widget _socialBtn({
    required IconData icon,
    required String label,
    required Color iconColor,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF0C1E2E),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: kWhite.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: kWhite,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
