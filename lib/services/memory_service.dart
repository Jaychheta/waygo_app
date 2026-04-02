import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/memory_model.dart';
import 'auth_service.dart';

class MemoryService {
  const MemoryService();

  final _auth = const AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _auth.getToken();
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  Future<List<MemoryModel>> getMemories(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/memories/$userId'),
        headers: headers,
      ).timeout(ApiConfig.requestTimeout);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => MemoryModel.fromJson(e)).toList();
      }
      return [];
    } on TimeoutException {
      return [];
    } on SocketException {
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetches ALL members' memories for a specific trip (for shared trip view)
  Future<List<MemoryModel>> getMemoriesByTrip(String tripName) async {
    try {
      final headers = await _getHeaders();
      final encoded = Uri.encodeComponent(tripName);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/memories/trip/$encoded'),
        headers: headers,
      ).timeout(ApiConfig.requestTimeout);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => MemoryModel.fromJson(e)).toList();
      }
      return [];
    } on TimeoutException {
      return [];
    } on SocketException {
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> uploadMemory({
    required int userId,
    required String tripName,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    try {
      final token = await _auth.getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/memories/upload'),
      );
      if (token != null) {
        request.headers["Authorization"] = "Bearer $token";
      }
      request.fields['user_id'] = userId.toString();
      request.fields['trip_name'] = tripName;
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: fileName,
      ));
      final response = await request.send().timeout(ApiConfig.requestTimeout);
      return response.statusCode == 200 || response.statusCode == 201;
    } on TimeoutException {
      return false;
    } on SocketException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteMemory(String memoryId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/memories/$memoryId'),
        headers: headers,
      ).timeout(ApiConfig.requestTimeout);
      return response.statusCode == 200;
    } on TimeoutException {
      return false;
    } on SocketException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateMemoryTripName(String memoryId, String newTripName) async {
    try {
      final headers = await _getHeaders();
      headers['Content-Type'] = 'application/json';
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/memories/$memoryId'),
        headers: headers,
        body: jsonEncode({'trip_name': newTripName}),
      ).timeout(ApiConfig.requestTimeout);
      return response.statusCode == 200;
    } on TimeoutException {
      return false;
    } on SocketException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
