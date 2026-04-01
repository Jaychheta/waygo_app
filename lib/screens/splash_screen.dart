import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import '../services/auth_service.dart';
import '../widgets/page_transitions.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(2600.ms);
    if (!mounted) return;
    
    // Check for existing session (Auto-Login Excellence)
    final token = await const AuthService().getToken();
    final name = await const AuthService().getUserName();
    
    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // Direct jump to Dashboard for returning travelers
      Navigator.of(context).pushReplacement(
        PageTransitions.slideUp(DashboardScreen(userName: name)),
      );
    } else {
      // Luxury transition to Login for new adventurers
      Navigator.of(context).pushReplacement(
        PageTransitions.fadeScale(const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Radiant Background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Color(0xFF1A1A2E),
                  kSurface,
                ],
              ),
            ),
          ),

          // 2. Animated Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              
              // Animated Logo / Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kSurface,
                  border: Border.all(color: kTeal.withValues(alpha: 0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: kTeal.withValues(alpha: 0.1),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: kTeal,
                  size: 48,
                ),
              )
              .animate()
              .scale(
                duration: 800.ms,
                curve: Curves.easeOutBack,
                begin: const Offset(0, 0),
              )
              .shimmer(delay: 800.ms, duration: 1200.ms, color: kWhite.withValues(alpha: 0.2))
              .blur(begin: const Offset(10, 10), end: const Offset(0, 0), duration: 600.ms),

              const SizedBox(height: 32),

              // Waygo Branding
              Column(
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        color: kWhite,
                      ),
                      children: [
                        TextSpan(text: 'Way'),
                        TextSpan(
                          text: 'go.',
                          style: TextStyle(color: kTeal),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 800.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCirc),

                  const SizedBox(height: 12),
                  
                  Text(
                    'THE LUXURY CONCIERGE',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w600,
                      color: kWhite.withValues(alpha: 0.4),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 1000.ms)
                  .blur(begin: const Offset(5, 5), end: const Offset(0, 0)),
                ],
              ),

              const Spacer(flex: 2),

              // Bottom subtle indicator
              SizedBox(
                width: 40,
                height: 2,
                child: LinearProgressIndicator(
                  backgroundColor: kWhite.withValues(alpha: 0.05),
                  valueColor: const AlwaysStoppedAnimation(kTeal),
                ),
              )
              .animate()
              .fadeIn(delay: 1200.ms)
              .scaleX(begin: 0, end: 1, duration: 1400.ms, curve: Curves.easeInOutExpo),
              
              const SizedBox(height: 60),
            ],
          ),
        ],
      ),
    );
  }
}
