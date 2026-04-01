import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class ExpenseService {
  const ExpenseService();

  final _auth = const AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _auth.getToken();
    final headers = {"Content-Type": "application/json"};
    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  Future<bool> addExpense({
    required int tripId,
    required int paidBy,
    required double amount,
    required String category,
    String description = '',
    List<int> splitWith = const [],
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/expenses/add'),
        headers: headers,
        body: jsonEncode({
          'trip_id': tripId,
          'paid_by': paidBy,
          'amount': amount,
          'category': category,
          'description': description,
          'split_with': splitWith,
        }),
      ).timeout(ApiConfig.requestTimeout);
      return response.statusCode == 200 || response.statusCode == 201;
    } on TimeoutException {
      return false;
    } on SocketException {
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getExpenses(int tripId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/expenses?trip_id=$tripId'),
        headers: headers,
      ).timeout(ApiConfig.requestTimeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } on TimeoutException {
      return [];
    } on SocketException {
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getSettlements(int tripId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/expenses/settlements?trip_id=$tripId'),
        headers: headers,
      ).timeout(ApiConfig.requestTimeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } on TimeoutException {
      return [];
    } on SocketException {
      return [];
    } catch (e) {
      return [];
    }
  }
}