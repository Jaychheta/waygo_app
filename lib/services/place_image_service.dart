import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:waygo_app/config/api_config.dart';

class PlaceImageService {
  PlaceImageService._();
  static final PlaceImageService instance = PlaceImageService._();

  final Map<String, String> _cache = {};

  Future<String> fetchImage({
    required String placeName,
    required String cityName,
    String category = 'General',
    String description = '',
  }) async {
    final cacheKey = '${placeName.toLowerCase()}|${cityName.toLowerCase()}';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    try {
      final encodedPlace = Uri.encodeComponent(placeName);
      final encodedCity = Uri.encodeComponent(cityName);
      
      // Use ApiConfig.baseUrl which already contains /api
      final url = Uri.parse('${ApiConfig.baseUrl}/place-image?place=$encodedPlace&city=$encodedCity');
      
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrl = data['imageUrl'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          _cache[cacheKey] = imageUrl;
          return imageUrl;
        }
      }
    } catch (_) {}

    // Fallback if proxy fails
    final fallback = _getCategoryFallback(category: category, description: description, placeName: placeName);
    _cache[cacheKey] = fallback;
    return fallback;
  }

  void clearCache() => _cache.clear();

  String _getCategoryFallback({
    required String category,
    required String description,
    required String placeName,
  }) {
    final text = '${category.toLowerCase()} ${description.toLowerCase()} ${placeName.toLowerCase()}';

    if (text.contains('temple') || text.contains('religious') || text.contains('mandir') || text.contains('mosque') || text.contains('church')) {
      return 'https://images.unsplash.com/photo-1564804955877-2c3c7f068cd3?w=800';
    }
    if (text.contains('fort') || text.contains('palace') || text.contains('mahal') || text.contains('heritage') || text.contains('monument')) {
      return 'https://images.unsplash.com/photo-1599661046289-e31897846e41?w=800';
    }
    if (text.contains('nature') || text.contains('park') || text.contains('garden') || text.contains('hill') || text.contains('lake') || text.contains('forest') || text.contains('river')) {
      return 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800';
    }
    if (text.contains('beach') || text.contains('coast') || text.contains('sea') || text.contains('ocean')) {
      return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800';
    }
    if (text.contains('food') || text.contains('cafe') || text.contains('restaurant') || text.contains('dining') || text.contains('dhaba')) {
      return 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800';
    }
    if (text.contains('museum') || text.contains('gallery') || text.contains('art') || text.contains('exhibit')) {
      return 'https://images.unsplash.com/photo-1554907984-15263bfd63bd?w=800';
    }

    return 'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=800';
  }
}