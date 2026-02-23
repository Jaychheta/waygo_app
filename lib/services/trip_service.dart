import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class TripService {
  const TripService();

  // નવી ટ્રિપ સેવ કરવા માટે
  Future<bool> createTrip({
    required int userId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/trips/create"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "name": name,
          "start_date": startDate.toIso8601String(),
          "end_date": endDate.toIso8601String(),
          "location": "India",
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ડેટાબેઝમાંથી ટ્રિપ્સ મેળવવા માટેનું નવું ફંક્શન
  Future<List<dynamic>> getUserTrips(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/trips/$userId"),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

Future<List<dynamic>> generateAiPlan(String location, int days) async {
  print("===> Calling API for $location, $days days...");
  try {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/api/trips/generate-ai-plan?location=$location&days=$days")
    );
    
    print("===> Status Code: ${response.statusCode}");
    print("===> Response Body: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Server Error: ${response.statusCode}');
    }
  } catch (e) {
    print("===> Flutter Exception: $e");
    rethrow;
  }
}