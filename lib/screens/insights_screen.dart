import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/glass_container.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

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
        title: const Text('TRAVEL INSIGHTS', style: TextStyle(color: kWhite, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildStatCard('Total Spent', '₹45,280', Icons.account_balance_wallet_rounded, kTeal),
            const SizedBox(height: 16),
            _buildStatCard('Distance Traveled', '1,240 KM', Icons.map_rounded, Colors.amber),
            const SizedBox(height: 16),
            _buildStatCard('Memories Saved', '14 Photos', Icons.camera_rounded, Colors.purpleAccent),
            const SizedBox(height: 32),
            GlassContainer(
              padding: const EdgeInsets.all(24),
              child: const Column(
                children: [
                  Icon(Icons.bar_chart_rounded, color: Colors.white24, size: 100),
                  SizedBox(height: 12),
                  Text('Detailed Insights are being generated.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('Keep traveling to see more patterns!', style: TextStyle(color: Colors.white24, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String val, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(val, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
