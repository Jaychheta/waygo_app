import 'package:flutter/material.dart';
import 'package:waygo_app/config/app_theme.dart';
import 'package:waygo_app/screens/dashboard_screen.dart';
import 'package:waygo_app/services/auth_service.dart';
import 'package:waygo_app/widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  static const String routeName = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authService = const AuthService();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    final result = await _authService.register(
      name: _nameCtrl.text.trim(),
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
                  const SizedBox(height: 16),

                  // ── Top bar: back + help ───────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: kWhite, size: 24),
                        ),
                      ),
                      const Text(
                        'Help',
                        style: TextStyle(
                          color: kTeal,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Title ──────────────────────────────────────────────
                  const Text(
                    'Create your\naccount',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: kWhite,
                      letterSpacing: -1,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Join thousands of travelers exploring the\nworld today.',
                    style: TextStyle(
                      color: kSlate,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Full Name ──────────────────────────────────────────
                  _fieldLabel('Full Name'),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: _nameCtrl,
                    hint: 'e.g. John Doe',
                    icon: Icons.person_outline_rounded,
                    validator: (v) =>
                        (v?.trim().length ?? 0) < 2 ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 20),

                  // ── Email ──────────────────────────────────────────────
                  _fieldLabel('Email Address'),
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
                    hint: 'Create a password',
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
                  const SizedBox(height: 32),

                  // ── Create Account button ──────────────────────────────
                  CustomButton(
                    text: 'Create Account',
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

                  // ── Social buttons ─────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _socialBtn(
                          icon: Icons.g_mobiledata_rounded,
                          label: 'Google',
                          iconColor: const Color(0xFFEA4335),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _socialBtn(
                          icon: Icons.apple_rounded,
                          label: 'Apple',
                          iconColor: kWhite,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // ── Sign in link ───────────────────────────────────────
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Already have an account?  ',
                          style: TextStyle(color: kSlate, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Log in',
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
