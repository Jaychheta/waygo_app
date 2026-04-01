import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/glass_container.dart';
import '../widgets/page_transitions.dart';

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
          backgroundColor: kDanger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      PageTransitions.slideUp(
        DashboardScreen(userName: result.user?.name ?? 'Traveler'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Gradient + Decorative Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kTeal.withValues(alpha: 0.05),
              ),
            ),
          ).animate().fadeIn(duration: 1200.ms),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    
                    // Header Section
                    const Text(
                      'Welcome\nBack.',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: -1.5,
                        color: kWhite,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideX(begin: -0.2, end: 0, curve: Curves.easeOutCubic),
                    
                    const SizedBox(height: 12),
                    
                    Text(
                      'Sign in to continue your global journey.',
                      style: TextStyle(
                        fontSize: 16,
                        color: kWhite.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms),
                    
                    const SizedBox(height: 48),

                    // Login Card (Glassmorphic)
                    GlassContainer(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildTextField(
                            label: 'Email Address',
                            controller: _emailCtrl,
                            hint: 'voyager@waygo.com',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if ((v?.trim() ?? '').isEmpty) return 'Email required';
                              if (!v!.contains('@')) return 'Invalid email format';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          _buildTextField(
                            label: 'Security Code',
                            controller: _passwordCtrl,
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscure,
                            validator: (v) => (v?.length ?? 0) < 6 ? 'Minimum 6 characters' : null,
                            suffix: IconButton(
                              icon: Icon(
                                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: kWhite.withValues(alpha: 0.3),
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: kTeal.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 800.ms)
                    .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), curve: Curves.easeOutBack),

                    const SizedBox(height: 32),

                    // Actions
                    CustomButton(
                      text: 'Sign In',
                      isLoading: _isLoading,
                      onPressed: _submit,
                    )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 800.ms),

                    const SizedBox(height: 24),

                    // Social Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: kWhite.withValues(alpha: 0.05))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'EXPLORE WITH',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w800,
                              color: kWhite.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: kWhite.withValues(alpha: 0.05))),
                      ],
                    )
                    .animate()
                    .fadeIn(delay: 800.ms),

                    const SizedBox(height: 24),

                    // Social Buttons
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Google',
                            variant: ButtonVariant.secondary,
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            text: 'Apple',
                            variant: ButtonVariant.secondary,
                            onPressed: () {},
                          ),
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(delay: 1000.ms, duration: 800.ms),

                    const SizedBox(height: 48),

                    // Footer
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          PageTransitions.fadeScale(const RegisterScreen()),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: kWhite.withValues(alpha: 0.5),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            children: const [
                              TextSpan(text: "New to Waygo? "),
                              TextSpan(
                                text: 'Create Account',
                                style: TextStyle(
                                  color: kTeal,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 1200.ms),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w800,
            color: kWhite.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.w600),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: kWhite.withValues(alpha: 0.15), fontWeight: FontWeight.w400),
            prefixIcon: Icon(icon, color: kTeal.withValues(alpha: 0.5), size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: kWhite.withValues(alpha: 0.05)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: kWhite.withValues(alpha: 0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kTeal, width: 1.5),
            ),
            errorStyle: const TextStyle(color: kDanger, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
