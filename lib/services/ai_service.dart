import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/itinerary_model.dart';

/// Fetches a real AI-generated itinerary from the backend.
/// Endpoint: GET /api/trips/generate-ai-plan?location={loc}&days={n}
class AiService {
  const AiService();

  Future<ItineraryModel> generateItinerary({
    required String location,
    required int days,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/trips/generate-ai-plan'
      '?location=${Uri.encodeComponent(location)}&days=$days',
    );

    final response = await http
        .get(uri)
        .timeout(ApiConfig.aiTimeout);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList =
          jsonDecode(response.body) as List<dynamic>;
      return ItineraryModel.fromJsonList(jsonList, location: location);
    } else {
      throw Exception(
        'Failed to generate itinerary (${response.statusCode}): ${response.body}',
      );
    }
  }
}
