import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/itinerary_model.dart';
import 'auth_service.dart';

class AiService {
  const AiService();

  Future<ItineraryModel> generateItinerary({
    required String location,
    required int days,
  }) async {
    final token = await const AuthService().getToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/itinerary/generate');
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'destination': location,
              'days': days,
            }),
          )
          .timeout(ApiConfig.aiTimeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];
          final daysList = data['days'] as List<dynamic>? ?? [];
          return ItineraryModel.fromJsonList(daysList, location: location);
        }
        if (body is List) {
          return ItineraryModel.fromJsonList(body, location: location);
        }
        throw Exception('Unexpected response structure');
      } else if (response.statusCode == 401) {
        throw Exception('Please login again to use the AI Planner.');
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (_) {
      return _fallbackGet(location, days, token);
    }
  }

  Future<ItineraryModel> _fallbackGet(String location, int days, String? token) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/trips/generate-ai-plan?location=${Uri.encodeComponent(location)}&days=$days',
    );
    final headers = { if (token != null) 'Authorization': 'Bearer $token' };

    try {
      final response = await http.get(uri, headers: headers).timeout(ApiConfig.aiTimeout);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return ItineraryModel.fromJsonList(decoded, location: location);
        } else if (decoded is Map<String, dynamic> && decoded['days'] is List) {
          return ItineraryModel.fromJsonList(decoded['days'] as List<dynamic>, location: location);
        }
        throw Exception('Unexpected response format');
      }
      throw Exception('Server Error: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to generate plan: $e');
    }
  }
}
