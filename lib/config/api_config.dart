import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // ─────────────────────────────────────────────────────────────────────────
  // ENVIRONMENT TOGGLE
  // Set to `true` before deploying to production (Render).
  // Set to `false` for local development.
  // ─────────────────────────────────────────────────────────────────────────
  static const bool isProduction = false;

  // ─── Raw base URLs ───────────────────────────────────────────────────────
  static const String _productionUrl  = 'https://waygo-backend-mhwb.onrender.com/api';
  static const String _localUrlWeb    = 'http://localhost:3001/api';   // browser / web-server
  static const String _localUrlMobile = 'http://10.0.2.2:3001/api';   // Android emulator

  /// Automatically resolves to the correct base URL based on the toggle and
  /// the current platform. Uses [kIsWeb] (flutter/foundation) — safe on Web,
  /// Android, iOS, and Desktop without importing dart:io.
  static String get baseUrl {
    if (isProduction) return _productionUrl;
    return kIsWeb ? _localUrlWeb : _localUrlMobile;
  }

  // ─── Endpoints ───────────────────────────────────────────────────────────
  static const String loginEndpoint    = '/auth/login';
  static const String registerEndpoint = '/auth/register';

  // ─── Keys ────────────────────────────────────────────────────────────────
  static const String tokenKey = 'auth_token';

  // ─── Timeouts ────────────────────────────────────────────────────────────
  /// AI generation endpoints (Gemini can take 15–30 s)
  static const Duration aiTimeout = Duration(seconds: 60);

  /// Regular REST calls — 60 s covers Render free-tier cold start
  static const Duration requestTimeout = Duration(seconds: 60);
}