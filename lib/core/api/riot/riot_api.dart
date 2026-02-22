import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:arena_chain_flutter/core/models/riot/riot_account_model.dart';
import 'package:arena_chain_flutter/core/models/riot/riot_match_detail_model.dart';
import 'package:arena_chain_flutter/core/models/riot/riot_tft_match_detail_model.dart';

class RiotApi {
  final String baseUrl = ApiConfig.baseUrl;

  Future<RiotAccountModel> fetchPlayerAccount({
    required String gameName,
    required String tagLine,
    required String region,
    required String token,
  }) async {
    try {
      print('RiotApi: POST to $baseUrl/riot-api/account');
      final response = await http.post(
        Uri.parse('$baseUrl/riot-api/account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'gameName': gameName,
          'tagLine': tagLine,
          'region': region,
        }),
      );

      print('RiotApi: Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return RiotAccountModel.fromJson(data);
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('RiotApi Error: $e');
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  Future<RiotMatchDetailModel> fetchMatchDetail({
    required String matchId,
    required String region,
    required String puuid,
    required String token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/riot-api/match/$matchId?region=$region&puuid=$puuid');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RiotMatchDetailModel.fromJson(data);
      } else {
        throw Exception('Error fetching match details: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<RiotAccountModel> fetchTftAccount({
    required String gameName,
    required String tagLine,
    required String region,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/riot-api/tft/account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'gameName': gameName,
          'tagLine': tagLine,
          'region': region,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return RiotAccountModel.fromJson(data);
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<RiotTftMatchDetailModel> fetchTftMatchDetail({
    required String matchId,
    required String region,
    required String puuid,
    required String token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/riot-api/tft/match/$matchId?region=$region&puuid=$puuid');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RiotTftMatchDetailModel.fromJson(data);
      } else {
        throw Exception('Error fetching TFT match details: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ── Account Linking ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> linkGameAccount({
    required String gameName,
    required String tagLine,
    required String region,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/riot-api/link-account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'gameName': gameName,
          'tagLine': tagLine,
          'region': region,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> verifyGameAccount({
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/riot-api/verify-account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getLinkStatus({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/riot-api/link-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> disconnectAccount({
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/riot-api/disconnect-account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }
}
