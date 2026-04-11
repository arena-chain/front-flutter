import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:arena_chain_flutter/core/models/stream_model.dart';

class StreamApi {
  final String _baseUrl = ApiConfig.baseUrl;

  Future<List<StreamModel>> getAllStreams() async {
    final response = await http.get(Uri.parse('$_baseUrl/stream'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => StreamModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<StreamModel>> getLiveStreams() async {
    final response = await http.get(Uri.parse('$_baseUrl/stream/live'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => StreamModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<StreamModel>> getStreamsByChannel(String channelId) async {
    final response = await http.get(Uri.parse('$_baseUrl/stream/channel/$channelId'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => StreamModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<StreamModel?> getStreamById(String id) async {
    final response = await http.get(Uri.parse('$_baseUrl/stream/$id'));
    if (response.statusCode == 200) {
      return StreamModel.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<Map<String, dynamic>> getRtcConfig() async {
    final response = await http.get(Uri.parse('$_baseUrl/stream/rtc-config'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ]
    };
  }
}
