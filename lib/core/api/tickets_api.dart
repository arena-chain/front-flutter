import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:arena_chain_flutter/core/models/ticket_model.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';

class TicketsApi {
  String get _base => ApiConfig.restApiRoot;
  String? _workingBase;
  static const Duration _timeout = Duration(seconds: 8);
  final TokenStorage _tokenStorage = TokenStorage();

  Future<Map<String, String>> _headers() async {
    final token = await _tokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  List<String> _candidateBases() {
    final configured = _base;
    final candidates = <String>[
      if (_workingBase case final String workingBase) workingBase,
      configured,
      'http://10.0.2.2:3000/api',
      'http://127.0.0.1:3000/api',
      'http://localhost:3000/api',
    ];
    final seen = <String>{};
    return candidates.where((b) => seen.add(b)).toList();
  }

  Future<dynamic> _getJson(String endpoint) async {
    Exception? lastError;
    final headers = await _headers();
    for (final base in _candidateBases()) {
      final uri = Uri.parse('$base$endpoint');
      try {
        final resp = await http.get(uri, headers: headers).timeout(_timeout);
        if (resp.statusCode == 200) {
          _workingBase = base;
          return jsonDecode(resp.body);
        }
        lastError = Exception('Failed request ${resp.statusCode}');
      } catch (e) {
        lastError = Exception(e.toString());
      }
    }
    throw lastError ?? Exception('Unable to reach tickets backend.');
  }

  Future<dynamic> _postJson(String endpoint, Map<String, dynamic> body) async {
    Exception? lastError;
    final headers = await _headers();
    for (final base in _candidateBases()) {
      final uri = Uri.parse('$base$endpoint');
      try {
        final resp = await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(_timeout);
        _workingBase = base;
        try {
          return jsonDecode(resp.body);
        } catch (_) {
          // If not json, fall through
        }
      } catch (e) {
        lastError = Exception(e.toString());
      }
    }
    throw lastError ?? Exception('Unable to reach tickets backend for post.');
  }

  Future<List<TicketModel>> getMyTickets(String userId) async {
    final data = await _getJson('/tickets/my-tickets?userId=$userId');
    if (data is List) {
      return data.map((e) => TicketModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<TicketModel>> getAllTickets() async {
    final data = await _getJson('/tickets');
    if (data is List) {
      return data.map((e) => TicketModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<TicketModel> getTicketDetails(String id) async {
    final data = await _getJson('/tickets/$id');
    return TicketModel.fromJson(data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> validateTicket(String ticketNumber) async {
    final data = await _postJson('/tickets/validate', {'ticketNumber': ticketNumber});
    return data as Map<String, dynamic>;
  }
}
