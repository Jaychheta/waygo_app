import "dart:convert";

import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";
import "package:waygo_app/config/api_config.dart";
import "package:waygo_app/models/user_model.dart";

class AuthResult {
  const AuthResult({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });

  final bool success;
  final String message;
  final String? token;
  final UserModel? user;
}

class AuthService {
  const AuthService();

  Map<String, String> get _headers => const {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}");

    try {
      final response = await http
          .post(
            uri,
            headers: _headers,
            body: jsonEncode({"email": email.trim(), "password": password}),
          )
          .timeout(ApiConfig.requestTimeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message = body["message"] as String? ?? "Login request completed";

      // Backend returns HTTP 200 with token on success (no 'success' field)
      if (response.statusCode != 200) {
        return AuthResult(success: false, message: message);
      }

      final token = body["token"] as String?;
      final userJson = body["user"] as Map<String, dynamic>?;
      final user = userJson != null ? UserModel.fromJson(userJson) : null;

      if (token == null || token.isEmpty) {
        return AuthResult(success: false, message: message);
      }

      await _saveToken(token);

      return AuthResult(
        success: true,
        message: message,
        token: token,
        user: user,
      );
    } catch (_) {
      return const AuthResult(
        success: false,
        message: "Unable to connect. Please check your network and try again.",
      );
    }
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}${ApiConfig.registerEndpoint}");

    try {
      final response = await http
          .post(
            uri,
            headers: _headers,
            body: jsonEncode({
              "name": name.trim(),
              "email": email.trim(),
              "password": password,
            }),
          )
          .timeout(ApiConfig.requestTimeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message =
          body["message"] as String? ?? "Registration request completed";

      // Backend returns HTTP 200 on success (no 'success' field)
      if (response.statusCode != 200 && response.statusCode != 201) {
        return AuthResult(success: false, message: message);
      }

      final userJson = body["user"] as Map<String, dynamic>?;
      final user = userJson != null ? UserModel.fromJson(userJson) : null;

      return AuthResult(success: true, message: message, user: user);
    } catch (_) {
      return const AuthResult(
        success: false,
        message: "Unable to connect. Please check your network and try again.",
      );
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConfig.tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConfig.tokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConfig.tokenKey);
  }
}
