import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:waygo_app/screens/dashboard_screen.dart";
import "package:waygo_app/screens/login_screen.dart";
import "package:waygo_app/screens/register_screen.dart";
import "package:waygo_app/screens/splash_screen.dart";

const Color kPrimaryBlue = Color(0xFF2563EB);
const Color kAccentTeal = Color(0xFF14B8A6);
const Color kDarkBackground = Color(0xFF071026);
const Color kDarkSurface = Color(0xFF0E1A33);

void main() {
  runApp(const WayGoApp());
}

class WayGoApp extends StatelessWidget {
  const WayGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: kPrimaryBlue,
      brightness: Brightness.dark,
      primary: kPrimaryBlue,
      secondary: kAccentTeal,
      surface: kDarkSurface,
    );

    return MaterialApp(
      title: "WayGo",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: kDarkBackground,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.dark(useMaterial3: true).textTheme,
        ),
        cardTheme: const CardThemeData(
          color: kDarkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF12203D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      routes: {
        "/": (_) => const SplashScreen(),
        LoginScreen.routeName: (_) => const LoginScreen(),
        RegisterScreen.routeName: (_) => const RegisterScreen(),
        DashboardScreen.routeName: (_) => const DashboardScreen(),
      },
      initialRoute: "/",
    );
  }
}
