import 'package:flutter/material.dart';
import 'package:waygo_app/config/app_theme.dart';
import 'package:waygo_app/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _progress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _ctrl.forward();
    _redirect();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _redirect() async {
    await Future<void>.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (ctx, animation, _) =>
            FadeTransition(opacity: animation, child: const LoginScreen()),
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
            colors: [Color(0xFF040D1A), Color(0xFF061026), Color(0xFF0C2040)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            // Globe icon with glow rings
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kTeal.withValues(alpha: 0.15), width: 1),
                  ),
                ),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kTeal.withValues(alpha: 0.25), width: 1),
                  ),
                ),
                // Main icon container
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0D2040),
                    border: Border.all(color: kTeal.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: kTeal.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.public_rounded, color: kWhite, size: 44),
                ),
              ],
            ),
            const SizedBox(height: 40),
            // WayGo title
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: 1),
                children: [
                  TextSpan(text: 'Way', style: TextStyle(color: kWhite)),
                  TextSpan(text: 'Go', style: TextStyle(color: kTeal)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'YOUR PREMIUM TRAVEL COMPANION',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 2.5,
                color: kSlate,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(flex: 2),
            // Animated loading bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _progress,
                    builder: (ctx, child) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress.value,
                        minHeight: 3,
                        backgroundColor: kNavy3,
                        valueColor: const AlwaysStoppedAnimation<Color>(kTeal),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Loading Experience...',
                    style: TextStyle(color: kSlate, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
