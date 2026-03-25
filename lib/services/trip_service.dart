import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class TripService {
  const TripService();

  final _auth = const AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _auth.getToken();
    final headers = {"Content-Type": "application/json"};
    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  // નવી ટ્રિપ સેવ કરવા માટે
  Future<int?> createTrip({
    required int userId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? token, 
  }) async {
    try {
      final headers = await _getHeaders();
      // If the caller provided a manual token, use it instead
      if (token != null) headers["Authorization"] = "Bearer $token";

      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/trips/create"),
        headers: headers,
        body: jsonEncode({
          "name": name,
          "start_date": startDate.toIso8601String(),
          "end_date": endDate.toIso8601String(),
          "location": "India",
        }),
      ).timeout(ApiConfig.requestTimeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['trip']?['id'] as int?;
      }
      return null;
    } catch (e) {
      print("Error creating trip: $e");
      return null;
    }
  }

  Future<bool> saveFullItinerary({
    required int userId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required List<Map<String, dynamic>> dayPlans,
    String? token,
  }) async {
    final tripId = await createTrip(
      userId: userId,
      name: name,
      startDate: startDate,
      endDate: endDate,
      token: token,
    );

    if (tripId == null) return false;

    final headers = await _getHeaders();
    if (token != null) headers["Authorization"] = "Bearer $token";

    for (var day in dayPlans) {
      final places = day['places'] as List<dynamic>? ?? [];
      for (var place in places) {
        try {
          await http.post(
            Uri.parse("${ApiConfig.baseUrl}/trips/add-place"),
            headers: headers,
            body: jsonEncode({
              "trip_id": tripId,
              "place_data": place,
            }),
          ).timeout(ApiConfig.requestTimeout);
        } catch (e) {
          print("Error adding place: $e");
        }
      }
    }
    return true;
  }

  Future<List<dynamic>> getUserTrips(int userId, {String? token}) async {
    try {
      final headers = await _getHeaders();
      if (token != null) headers["Authorization"] = "Bearer $token";

      final url = "${ApiConfig.baseUrl}/trips/my";

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(ApiConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Error fetching trips: $e");
      return [];
    }
  }

  Future<List<dynamic>> getTripExpenses(int tripId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/trips/trip/$tripId/expenses"),
        headers: headers,
      ).timeout(ApiConfig.requestTimeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Error fetching trip expenses: $e");
      return [];
    }
  }

  Future<bool> addExpense({
    required int tripId,
    required String title,
    required double amount,
    String? category,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/trips/add-expense"),
        headers: headers,
        body: jsonEncode({
          "trip_id": tripId,
          "title": title,
          "amount": amount,
          "category": category ?? "Others",
        }),
      ).timeout(ApiConfig.requestTimeout);
      return response.statusCode == 200;
    } catch (e) {
      print("Error adding expense: $e");
      return false;
    }
  }

  static Future<List<dynamic>> generateAiPlan(String location, int days) async {
    try {
      final token = await const AuthService().getToken();
      final headers = <String, String>{};
      if (token != null) headers["Authorization"] = "Bearer $token";

      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/trips/generate-ai-plan?location=$location&days=$days"),
        headers: headers
      ).timeout(ApiConfig.aiTimeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      print("AI Plan Exception: $e");
      rethrow;
    }
  }
}