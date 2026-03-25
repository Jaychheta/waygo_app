import "dart:async";
import "dart:convert";
import "dart:io";

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

  /// Safely decodes a JSON response body. Returns null if the body is not
  /// valid JSON (e.g. plain-text "Server Error" from an uncaught backend exception).
  Map<String, dynamic>? _safeJsonDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

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

      final body = _safeJsonDecode(response.body);
      final message = body?["message"] as String? ?? "Login request completed";

      // Backend returns HTTP 200 with token on success
      if (response.statusCode != 200) {
        return AuthResult(success: false, message: message);
      }

      final token = body?["token"] as String?;
      final userJson = body?["user"] as Map<String, dynamic>?;
      final user = userJson != null ? UserModel.fromJson(userJson) : null;

      if (token == null || token.isEmpty) {
        return AuthResult(success: false, message: message);
      }

      await _saveToken(token);
      if (user != null) await _saveUserData(user);

      return AuthResult(
        success: true,
        message: message,
        token: token,
        user: user,
      );
    } on TimeoutException {
      return const AuthResult(
        success: false,
        message: "Server is waking up, please try again in a few seconds.",
      );
    } on SocketException {
      return const AuthResult(
        success: false,
        message: "Unable to connect to the server. Please check your internet connection.",
      );
    } catch (e) {
      return const AuthResult(
        success: false,
        message: "Something went wrong. Please try again.",
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

      final body = _safeJsonDecode(response.body);
      final message =
          body?["message"] as String? ?? "Registration request completed";

      // Backend returns HTTP 200/201 on success
      if (response.statusCode != 200 && response.statusCode != 201) {
        return AuthResult(success: false, message: message);
      }

      final userJson = body?["user"] as Map<String, dynamic>?;
      final user = userJson != null ? UserModel.fromJson(userJson) : null;

      // Also save token + user data on registration
      final token = body?["token"] as String?;
      if (token != null && token.isNotEmpty) {
        await _saveToken(token);
      }
      if (user != null) await _saveUserData(user);

      return AuthResult(success: true, message: message, token: token, user: user);
    } on TimeoutException {
      return const AuthResult(
        success: false,
        message: "Server is waking up, please try again in a few seconds.",
      );
    } on SocketException {
      return const AuthResult(
        success: false,
        message: "Unable to connect to the server. Please check your internet connection.",
      );
    } catch (e) {
      return const AuthResult(
        success: false,
        message: "Something went wrong. Please try again.",
      );
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConfig.tokenKey, token);
  }

  Future<void> _saveUserData(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_id', user.id);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConfig.tokenKey);
  }

  Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name') ?? 'Traveler';
  }

  Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email') ?? '';
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConfig.tokenKey);
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_id');
  }
}
