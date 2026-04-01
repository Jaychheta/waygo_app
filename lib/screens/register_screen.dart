import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import 'dashboard_screen.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/glass_container.dart';
import '../widgets/page_transitions.dart';

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
          backgroundColor: kDanger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      PageTransitions.slideUp(DashboardScreen(userName: result.user?.name ?? 'Traveler')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kWhite, size: 20),
                ).animate().fadeIn().slideX(begin: -0.5, end: 0),
                const SizedBox(height: 40),
                const Text(
                  'JOIN THE\nELITE VOYAGE.',
                  style: TextStyle(color: kWhite, fontSize: 44, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -2),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 12),
                Text(
                  'Begin your journey into curated luxury.',
                  style: TextStyle(color: kWhite.withValues(alpha: 0.3), fontSize: 16, fontWeight: FontWeight.w500),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 60),
                _fieldHeader('IDENTITY'),
                const SizedBox(height: 12),
                _glassField(_nameCtrl, 'Full Name', Icons.person_rounded),
                const SizedBox(height: 24),
                _fieldHeader('SECURE EMAIL'),
                const SizedBox(height: 12),
                _glassField(_emailCtrl, 'Email Address', Icons.alternate_email_rounded),
                const SizedBox(height: 24),
                _fieldHeader('PASSCODE'),
                const SizedBox(height: 12),
                _glassField(_passwordCtrl, '••••••••', Icons.lock_rounded, obscure: _obscure, suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: kTeal, size: 18),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )),
                const SizedBox(height: 60),
                CustomButton(text: 'ELEVATE ACCESS', isLoading: _isLoading, onPressed: _submit),
                const SizedBox(height: 32),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('ALREADY A MEMBER? SIGN IN', style: TextStyle(color: kWhite.withValues(alpha: 0.2), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldHeader(String text) {
    return Text(text, style: TextStyle(color: kWhite.withValues(alpha: 0.2), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2));
  }

  Widget _glassField(TextEditingController ctrl, String hint, IconData icon, {bool obscure = false, Widget? suffix}) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      radius: 16,
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(color: kWhite, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: kWhite.withValues(alpha: 0.1)),
          prefixIcon: Icon(icon, color: kTeal, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
