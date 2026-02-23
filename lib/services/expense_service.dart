import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ExpenseService {
  const ExpenseService();

  Future<bool> addExpense({
    required int tripId,
    required int paidBy,
    required double amount,
    required String category,
    String description = '',
    List<int> splitWith = const [],
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/expenses/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'trip_id': tripId,
          'paid_by': paidBy,
          'amount': amount,
          'category': category,
          'description': description,
          'split_with': splitWith,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getExpenses(int tripId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/expenses?trip_id=$tripId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getSettlements(int tripId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/expenses/settlements?trip_id=$tripId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}