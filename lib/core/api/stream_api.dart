import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:arena_chain_flutter/core/models/stream_model.dart';

class StreamApiException implements Exception {
  final String message;

  const StreamApiException(this.message);

  @override
  String toString() => message;
}

class StreamApi {
  final String _baseUrl = ApiConfig.baseUrl;

  Map<String, String> get _headers => const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<List<dynamic>> _getList(String path) async {
    final response = await http.get(Uri.parse('$_baseUrl$path'), headers: _headers);
    if (response.statusCode != 200) {
      throw StreamApiException('Failed to load streams (${response.statusCode}).');
    }

    final decoded = json.decode(response.body);
    if (decoded is List<dynamic>) {
      return decoded;
    }

    throw const StreamApiException('Unexpected stream list response.');
  }

  Future<Map<String, dynamic>> _getMap(String path) async {
    final response = await http.get(Uri.parse('$_baseUrl$path'), headers: _headers);
    if (response.statusCode != 200) {
      throw StreamApiException('Failed to load stream (${response.statusCode}).');
    }

    final decoded = json.decode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    throw const StreamApiException('Unexpected stream response.');
  }

  Future<List<StreamModel>> getAllStreams() async {
    final data = await _getList('/stream');
    return data
        .map((json) => StreamModel.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  Future<List<StreamModel>> getLiveStreams() async {
    final all = await getAllStreams();
    return all.where((s) => s.isLive).toList();
  }

  Future<List<StreamModel>> getStreamsByChannel(String channelId) async {
    final data = await _getList('/stream/channel/$channelId');
    return data
        .map((json) => StreamModel.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  Future<StreamModel?> getStreamById(String id) async {
    final data = await _getMap('/stream/$id');
    return StreamModel.fromJson(data);
  }

  Future<Map<String, dynamic>> getRtcConfig() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/stream/rtc-config'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }
    return {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ]
    };
  }
}
