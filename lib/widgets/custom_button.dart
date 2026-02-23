import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.height = 56,
    this.outlined = false,
    this.color,
    this.textColor,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final bool outlined;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final disabled = isLoading || onPressed == null;

    if (outlined) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color ?? kTeal, width: 1.5),
            foregroundColor: color ?? kTeal,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
          ),
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kRadius),
        gradient: color != null
            ? LinearGradient(colors: [color!, color!])
            : kTealGradient,
        boxShadow: disabled
            ? []
            : [
                BoxShadow(
                  color: (color ?? kTeal).withValues(alpha: 0.40),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: textColor ?? kWhite,
            disabledForegroundColor: kWhite.withValues(alpha: 0.6),
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(kWhite),
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.3),
                ),
        ),
      ),
    );
  }
}
