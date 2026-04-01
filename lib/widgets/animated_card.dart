import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';

/// Animated card with scale + opacity press feedback AND optional stagger entrance.
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressScale;
  final bool enabled;
  final int? index; // For stagger entrance

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressScale = 0.96,
    this.enabled = true,
    this.index,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: kDurMicro);
    _scaleAnim = Tween<double>(begin: 1.0, end: widget.pressScale).animate(
      CurvedAnimation(parent: _ctrl, curve: kCurveSnap),
    );
    _opacityAnim = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: kCurveSnap),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.enabled && widget.onTap != null) _ctrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.enabled && widget.onTap != null) {
      _ctrl.reverse();
      widget.onTap?.call();
    }
  }

  void _onTapCancel() {
    if (widget.enabled && widget.onTap != null) _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      onLongPress: widget.onLongPress,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Transform.scale(
            scale: _scaleAnim.value,
            child: Opacity(
              opacity: _opacityAnim.value,
              child: child,
            ),
          ),
          child: widget.child,
        ),
      ),
    );

    if (widget.index != null) {
      return content.animate()
        .fadeIn(delay: (widget.index! * 40).ms, duration: 600.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
    }

    return content;
  }
}
