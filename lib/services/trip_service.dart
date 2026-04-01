import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/trip_model.dart';
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

  Future<int?> createTrip({
    required int userId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? token, 
  }) async {
    try {
      final headers = await _getHeaders();
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
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['trip']?['id'] as int? ?? data['id'] as int?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<TripModel>> getUserTrips(int userId, {String? token}) async {
    try {
      final headers = await _getHeaders();
      if (token != null) headers["Authorization"] = "Bearer $token";

      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/trips/my"),
        headers: headers,
      ).timeout(ApiConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TripModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getTripPlaces(int tripId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/trips/trip/$tripId/places"),
        headers: headers,
      ).timeout(ApiConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> addPlace(int tripId, Map<String, dynamic> placeData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/trips/add-place"),
        headers: headers,
        body: jsonEncode({
          "trip_id": tripId,
          "place_data": placeData,
        }),
      ).timeout(ApiConfig.requestTimeout);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> saveFullItinerary({
    required int userId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required List<dynamic> dayPlans,
    String? token,
  }) async {
    try {
      final headers = await _getHeaders();
      if (token != null) headers["Authorization"] = "Bearer $token";

      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/trips/ai/save-full"),
        headers: headers,
        body: jsonEncode({
          "userId": userId,
          "name": name,
          "startDate": startDate.toIso8601String(),
          "endDate": endDate.toIso8601String(),
          "dayPlans": dayPlans,
        }),
      ).timeout(ApiConfig.requestTimeout);
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
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
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}