import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Existing Brand Colors (preserved) ───────────────────────────────────────
const Color kNavy      = Color(0xFF061026);
const Color kNavy2     = Color(0xFF0D1F3C);
const Color kNavy3     = Color(0xFF122040);
const Color kTeal      = Color(0xFF14B8A6);
const Color kTealDark  = Color(0xFF0D9488);
const Color kSlate     = Color(0xFF94A3B8);
const Color kWhite     = Colors.white;

// ─── New: Glass Layer Colors ──────────────────────────────────────────────────
const Color kGlass       = Color(0x14FFFFFF); // 8% white overlay
const Color kGlassBorder = Color(0x28FFFFFF); // 16% white border

// ─── New: Surface Colors ──────────────────────────────────────────────────────
const Color kSurface     = Color(0xFF111111); // primary card surface
const Color kSurface2    = Color(0xFF1A1A1A); // elevated card surface

// ─── New: Accent Colors ───────────────────────────────────────────────────────
const Color kTealGlow     = Color(0xFF00BFA5); // vivid teal glow
const Color kPurpleAccent = Color(0xFF7C3AED); // AI / premium features
const Color kGoldAccent   = Color(0xFFF4C430); // luxury highlights
const Color kDanger       = Color(0xFFFF5252); // delete / error

// ─── New: Text Hierarchy ──────────────────────────────────────────────────────
const Color kTextPrimary   = Color(0xFFF5F5F5);
const Color kTextSecondary = Color(0xFF9E9E9E);
const Color kTextMuted     = Color(0xFF616161);

// ─── Existing Gradients (preserved) ──────────────────────────────────────────
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

// ─── Existing Border Radii (preserved) ───────────────────────────────────────
const double kRadius   = 20.0;
const double kRadius12 = 12.0;
const double kRadius16 = 16.0;

// ─── New: Animation Durations — 3-tier system ────────────────────────────────
const Duration kDurMicro = Duration(milliseconds: 120); // tap feedback
const Duration kDurFast  = Duration(milliseconds: 220); // state changes
const Duration kDurMed   = Duration(milliseconds: 380); // screen elements
const Duration kDurSlow  = Duration(milliseconds: 600); // page transitions
const Duration kDurXSlow = Duration(milliseconds: 900); // hero / onboarding

// ─── New: Animation Curves ────────────────────────────────────────────────────
const Curve kCurveSpring     = Cubic(0.34, 1.56, 0.64, 1.0); // bouncy
const Curve kCurveSnap       = Cubic(0.25, 0.46, 0.45, 0.94); // snappy
const Curve kCurveSmooth     = Cubic(0.4,  0.0,  0.2,  1.0);  // material
const Curve kCurveDecelerate = Curves.decelerate;              // settling

// ─── New: Spacing Scale (8pt grid) ───────────────────────────────────────────
const double kSp4  = 4.0;
const double kSp8  = 8.0;
const double kSp12 = 12.0;
const double kSp16 = 16.0;
const double kSp20 = 20.0;
const double kSp24 = 24.0;
const double kSp32 = 32.0;
const double kSp48 = 48.0;
const double kSp64 = 64.0;

// ─── New: Typography Scale ────────────────────────────────────────────────────
const TextStyle kHeadXL = TextStyle(
  fontSize: 32, fontWeight: FontWeight.w700,
  color: kTextPrimary, letterSpacing: -0.8, height: 1.15);

const TextStyle kHeadLG = TextStyle(
  fontSize: 24, fontWeight: FontWeight.w600,
  color: kTextPrimary, letterSpacing: -0.4, height: 1.2);

const TextStyle kHeadMD = TextStyle(
  fontSize: 18, fontWeight: FontWeight.w600,
  color: kTextPrimary, letterSpacing: -0.2);

const TextStyle kBodyLG = TextStyle(
  fontSize: 16, fontWeight: FontWeight.w400,
  color: kTextPrimary, height: 1.6);

const TextStyle kBodySM = TextStyle(
  fontSize: 13, fontWeight: FontWeight.w400,
  color: kTextSecondary, height: 1.5);

const TextStyle kLabel = TextStyle(
  fontSize: 12, fontWeight: FontWeight.w500,
  color: kTextMuted, letterSpacing: 0.6);

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

// ─── Decoration Helpers ───────────────────────────────────────────────────────

/// Original card decorator (preserved for backward compatibility)
BoxDecoration cardDecor({double radius = kRadius, Color? color}) => BoxDecoration(
  color: color ?? kNavy2,
  borderRadius: BorderRadius.circular(radius),
);

/// Upgraded dual-layer glow — deep and luxurious
BoxDecoration glowDecor({Color color = kTealGlow, double blur = 28}) =>
  BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(color: color.withValues(alpha: 0.40), blurRadius: blur,
                spreadRadius: 0, offset: const Offset(0, 4)),
      BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: blur * 2,
                spreadRadius: -4, offset: const Offset(0, 8)),
    ],
  );

/// Glassmorphism card — use with BackdropFilter in widget tree
BoxDecoration glassMorphDecor({double radius = 20, double opacity = 0.08}) =>
  BoxDecoration(
    color: Colors.white.withValues(alpha: opacity),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: kGlassBorder, width: 1.0),
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20, spreadRadius: -4),
    ],
  );

/// Dark luxury card — primary card style across all redesigned screens
BoxDecoration luxuryCardDecor({double radius = 16}) =>
  BoxDecoration(
    color: kSurface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xFF2A2A2A), width: 1.0),
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 16, offset: const Offset(0, 8)),
    ],
  );
