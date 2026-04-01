import 'package:flutter/material.dart';
import '../config/app_theme.dart';

enum ButtonVariant { primary, secondary, ghost, danger }

class CustomButton extends StatefulWidget {
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.height = 56,
    this.variant = ButtonVariant.primary,
    // Legacy params preserved for backward compatibility
    this.outlined = false,
    this.color,
    this.textColor,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final ButtonVariant variant;
  final bool outlined;
  final Color? color;
  final Color? textColor;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: kDurMicro);
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: kCurveSnap),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _disabled => widget.isLoading || widget.onPressed == null;

  void _onTapDown(TapDownDetails _) {
    if (!_disabled) _ctrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (!_disabled) {
      _ctrl.reverse();
      widget.onPressed?.call();
    }
  }

  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    // Resolve colors by variant (or legacy color override)
    final Color fillColor;
    final Color labelColor;
    final Color? borderColor;
    final Gradient? gradient;

    if (widget.color != null) {
      // Legacy behavior
      fillColor = widget.color!;
      labelColor = widget.textColor ?? kWhite;
      borderColor = widget.outlined ? widget.color : null;
      gradient = widget.outlined ? null : LinearGradient(colors: [widget.color!, widget.color!]);
    } else {
      switch (widget.variant) {
        case ButtonVariant.primary:
          fillColor = kTeal;
          labelColor = Colors.black;
          borderColor = null;
          gradient = kTealGradient;
        case ButtonVariant.secondary:
          fillColor = kSurface;
          labelColor = kTeal;
          borderColor = kTeal;
          gradient = null;
        case ButtonVariant.ghost:
          fillColor = Colors.transparent;
          labelColor = kTextSecondary;
          borderColor = null;
          gradient = null;
        case ButtonVariant.danger:
          fillColor = kDanger;
          labelColor = kWhite;
          borderColor = null;
          gradient = LinearGradient(colors: [kDanger, kDanger]);
      }
    }

    final Widget label = Text(
      widget.text,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 15,
        letterSpacing: 0.3,
        color: labelColor,
      ),
    );

    const Widget loader = SizedBox(
      height: 18,
      width: 18,
      child: CircularProgressIndicator(
        strokeWidth: 1.8,
        valueColor: AlwaysStoppedAnimation<Color>(kWhite),
      ),
    );

    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (_, child) => Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          ),
          child: Container(
            width: double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              color: gradient == null ? fillColor : null,
              gradient: _disabled ? null : gradient,
              borderRadius: BorderRadius.circular(kRadius),
              border: borderColor != null
                  ? Border.all(color: borderColor, width: 1.5)
                  : null,
              boxShadow: _disabled || gradient == null
                  ? []
                  : [
                      BoxShadow(
                        color: fillColor.withValues(alpha: 0.40),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(kRadius),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _disabled ? null : widget.onPressed,
                  splashColor: kWhite.withValues(alpha: 0.1),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: kDurFast,
                      child: widget.isLoading
                          ? SizedBox(key: const ValueKey(true), child: loader)
                          : SizedBox(key: const ValueKey(false), child: label),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
