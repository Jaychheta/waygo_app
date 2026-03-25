import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/memory_model.dart';

class MemoryService {
  const MemoryService();

  Future<List<MemoryModel>> getMemories(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/memories/$userId'),
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
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/memories/upload'),
      );
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
}
