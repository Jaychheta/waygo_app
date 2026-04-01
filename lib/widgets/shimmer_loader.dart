import 'package:flutter/material.dart';

/// Reusable shimmer box — pure Flutter, no packages.
/// Gradient sweeps left-to-right to simulate a loading skeleton.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8.0,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -2.0, end: 2.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(_anim.value - 1, 0),
              end: Alignment(_anim.value + 1, 0),
              colors: const [
                Color(0xFF1E1E1E),
                Color(0xFF2E2E2E),
                Color(0xFF1E1E1E),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton for a trip card: hero image + 2 text lines + a chip.
class ShimmerTripCard extends StatelessWidget {
  const ShimmerTripCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 240, height: 180, radius: 20),
          const SizedBox(height: 10),
          const ShimmerBox(width: 160, height: 16, radius: 6),
          const SizedBox(height: 6),
          const ShimmerBox(width: 100, height: 12, radius: 6),
          const SizedBox(height: 8),
          ShimmerBox(width: 70, height: 22, radius: 11),
        ],
      ),
    );
  }
}

/// Skeleton for a vertical list row: avatar circle + 2 text lines.
class ShimmerListItem extends StatelessWidget {
  const ShimmerListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const ShimmerBox(width: 40, height: 40, radius: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ShimmerBox(width: 140, height: 14, radius: 6),
              SizedBox(height: 6),
              ShimmerBox(width: 90, height: 11, radius: 6),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton for a stat card: square block + a text line below.
class ShimmerStatCard extends StatelessWidget {
  const ShimmerStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ShimmerBox(width: 80, height: 80, radius: 16),
        SizedBox(height: 8),
        ShimmerBox(width: 60, height: 12, radius: 6),
      ],
    );
  }
}
