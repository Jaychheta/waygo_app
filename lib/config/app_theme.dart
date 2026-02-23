import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Brand Colors ───────────────────────────────────────────────────────────
const Color kNavy      = Color(0xFF061026);   // deep background
const Color kNavy2     = Color(0xFF0D1F3C);   // card / surface
const Color kNavy3     = Color(0xFF122040);   // elevated surface
const Color kTeal      = Color(0xFF14B8A6);   // primary accent
const Color kTealDark  = Color(0xFF0D9488);   // pressed / shadow teal
const Color kSlate     = Color(0xFF94A3B8);   // muted text
const Color kWhite     = Colors.white;

// ─── Gradients ───────────────────────────────────────────────────────────────
const LinearGradient kTealGradient = LinearGradient(
  colors: [kTeal, kTealDark],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kBgGradient = LinearGradient(
  colors: [Color(0xFF081528), kNavy],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

// ─── Border Radii ────────────────────────────────────────────────────────────
const double kRadius   = 20.0;
const double kRadius12 = 12.0;
const double kRadius16 = 16.0;

// ─── App-wide ThemeData ──────────────────────────────────────────────────────
ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: kNavy,
    colorScheme: const ColorScheme.dark(
      primary: kTeal,
      secondary: kTeal,
      surface: kNavy2,
      onPrimary: kWhite,
      onSecondary: kWhite,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: kWhite,
      displayColor: kWhite,
    ),
    cardTheme: CardThemeData(
      color: kNavy2,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kNavy3,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadius12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadius12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadius12),
        borderSide: const BorderSide(color: kTeal, width: 1.5),
      ),
      hintStyle: const TextStyle(color: kSlate, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0C1B35),
      selectedItemColor: kTeal,
      unselectedItemColor: kSlate,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      elevation: 20,
    ),
  );
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
BoxDecoration cardDecor({double radius = kRadius, Color? color}) => BoxDecoration(
  color: color ?? kNavy2,
  borderRadius: BorderRadius.circular(radius),
);

BoxDecoration glowDecor({Color glowColor = kTeal, double radius = kRadius}) => BoxDecoration(
  borderRadius: BorderRadius.circular(radius),
  gradient: kTealGradient,
  boxShadow: [
    BoxShadow(
      color: glowColor.withValues(alpha: 0.35),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ],
);
