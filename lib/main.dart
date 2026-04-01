import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:waygo_app/config/app_theme.dart';
import 'package:waygo_app/screens/dashboard_screen.dart';
import 'package:waygo_app/screens/login_screen.dart';
import 'package:waygo_app/screens/register_screen.dart';
import 'package:waygo_app/screens/splash_screen.dart';
import 'package:waygo_app/services/place_image_service.dart';

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Luxury optimization: Set system overlay for OLED-ready transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: kSurface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Clear stale image cache so fresh city photos are always fetched
  PlaceImageService.instance.clearCache();
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
