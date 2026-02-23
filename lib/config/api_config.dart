import 'package:flutter/foundation.dart'; // kIsWeb માટે આ જરૂરી છે

class ApiConfig {
  // આપોઆપ નક્કી કરશે કે કયો URL વાપરવો
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:3000/api"; // Chrome માટે
    } else {
      return "http://10.0.2.2:3000/api"; // Android Emulator માટે
    }
  }

  // Endpoints
  static const String loginEndpoint = "/auth/login";
  static const String registerEndpoint = "/auth/register";

  // Keys
  static const String tokenKey = "auth_token";

  // Timeout for AI generation endpoints (Gemini can take 15-30 s)
  static const Duration aiTimeout = Duration(seconds: 60);

  // Timeout for regular REST calls
  static const Duration requestTimeout = Duration(seconds: 20);
}