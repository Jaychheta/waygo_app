import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:waygo_app/config/app_theme.dart';
import 'package:waygo_app/screens/dashboard_screen.dart';
import 'package:waygo_app/screens/login_screen.dart';
import 'package:waygo_app/screens/register_screen.dart';
import 'package:waygo_app/screens/splash_screen.dart';

void main() {
  runApp(const WayGoApp());
}

class WayGoApp extends StatelessWidget {
  const WayGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WayGo',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme().copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark(useMaterial3: true).textTheme,
        ).apply(bodyColor: kWhite, displayColor: kWhite),
      ),
      routes: {
        '/': (_) => const SplashScreen(),
        LoginScreen.routeName: (_) => const LoginScreen(),
        RegisterScreen.routeName: (_) => const RegisterScreen(),
        DashboardScreen.routeName: (_) => const DashboardScreen(),
      },
      initialRoute: '/',
    );
  }
}
