import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:arena_chain_flutter/core/models/video_model.dart';

class VideoApi {
  final String _baseUrl = ApiConfig.baseUrl;

  Future<List<Video>> getVideos({String? uploaderId}) async {
    final response = await http.get(Uri.parse('$_baseUrl/video'));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch videos (${response.statusCode})');
    }

    final dynamic decoded = jsonDecode(response.body);
    final List<dynamic> data =
        decoded is List ? decoded : (decoded['data'] as List<dynamic>? ?? []);

    final videos = data
        .whereType<Map<String, dynamic>>()
        .map(Video.fromJson)
        .toList();

    if (uploaderId == null || uploaderId.isEmpty) {
      return videos;
    }

    return videos.where((video) => video.uploaderId == uploaderId).toList();
  }

  Future<Video> uploadVideo({
    required String filePath,
    required String title,
    required String uploaderId,
    String? description,
    String? token,
  }) async {
    final uri = Uri.parse('$_baseUrl/video/upload');
    final request = http.MultipartRequest('POST', uri);

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['title'] = title;
    request.fields['uploader'] = uploaderId;
    if (description != null && description.trim().isNotEmpty) {
      request.fields['description'] = description.trim();
    }

    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode != 200 && streamedResponse.statusCode != 201) {
      throw Exception('Upload failed (${streamedResponse.statusCode}): $responseBody');
    }

    final dynamic decoded = jsonDecode(responseBody);
    final Map<String, dynamic> payload = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'data': decoded};

    if (payload['data'] is Map<String, dynamic>) {
      return Video.fromJson(payload['data'] as Map<String, dynamic>);
    }
    return Video.fromJson(payload);
  }
}
