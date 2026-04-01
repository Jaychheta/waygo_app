import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/glass_container.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  const PlaceholderScreen({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: const TextStyle(color: kWhite, fontWeight: FontWeight.w900)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: kTeal.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: kTeal.withValues(alpha: 0.1), width: 2),
              ),
              child: Icon(icon, color: kTeal, size: 80),
            ),
            const SizedBox(height: 40),
            Text(
              '$title Module',
              style: const TextStyle(color: kWhite, fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              'Initializing luxury $title systems...',
              style: TextStyle(color: kWhite.withValues(alpha: 0.3), fontSize: 14),
            ),
            const SizedBox(height: 60),
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              radius: 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: kTeal, strokeWidth: 2)),
                  const SizedBox(width: 16),
                  Text('Loading Data...', style: TextStyle(color: kTeal.withValues(alpha: 0.7), fontWeight: FontWeight.w900, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
