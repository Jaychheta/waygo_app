import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Frosted glass container using BackdropFilter.
/// Wrap in a Stack over an image/gradient for full effect.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final double opacity;
  final bool showBorder;
  final double blurSigma;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.radius = 20.0,
    this.padding,
    this.opacity = 0.08,
    this.showBorder = true,
    this.blurSigma = 16.0,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(radius),
            border: showBorder
                ? Border.all(color: kGlassBorder, width: 1.0)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: -4,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
