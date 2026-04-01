import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class PageTransitions {
  static Route slideUp(Widget page) => SlideUpRoute(page: page);
  static Route fadeScale(Widget page) => FadeScaleRoute(page: page);
  static Route sharedAxis(Widget page, {bool reverse = false}) => 
      SharedAxisRoute(page: page, reverse: reverse);
}

/// Slides up from a slight vertical offset + fades in.
class SlideUpRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideUpRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: kDurSlow,
          reverseTransitionDuration: kDurMed,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slide = Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: kCurveSmooth));

            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: kCurveSmooth),
              child: SlideTransition(position: slide, child: child),
            );
          },
        );
}

/// Scales from 0.94 and fades in simultaneously.
class FadeScaleRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeScaleRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: kDurMed,
          reverseTransitionDuration: kDurFast,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scale = Tween<double>(begin: 0.94, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: kCurveDecelerate),
            );
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: kCurveDecelerate),
              child: ScaleTransition(scale: scale, child: child),
            );
          },
        );
}

/// Horizontal slide + fade.
class SharedAxisRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final bool reverse;

  SharedAxisRoute({required this.page, this.reverse = false})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: kDurMed,
          reverseTransitionDuration: kDurFast,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slide = Tween<Offset>(
              begin: Offset(reverse ? -0.04 : 0.04, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: kCurveSmooth));

            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: kCurveSmooth),
              child: SlideTransition(position: slide, child: child),
            );
          },
        );
}
