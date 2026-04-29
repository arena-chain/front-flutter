import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';

/// Player-facing public highlights feed (`GET /api/highlights/public`).
/// See `MOBILE_HIGHLIGHTS_FEED_GUIDE.md`.
class HighlightsFeedApi {
  static const Duration _timeout = Duration(seconds: 8);
  String? _workingApiRoot;

  String get _configuredApiRoot => '${ApiConfig.baseUrl}/api';

  List<String> _candidateApiRoots() {
    final candidates = <String>[
      if (_workingApiRoot case final String working) working,
      _configuredApiRoot,
      'http://10.0.2.2:3000/api',
      'http://127.0.0.1:3000/api',
      'http://localhost:3000/api',
    ];
    final seen = <String>{};
    return candidates.where((b) => seen.add(b)).toList();
  }

  Future<List<HighlightItem>> fetchPublicHighlights() async {
    Exception? lastError;
    for (final root in _candidateApiRoots()) {
      final uri = Uri.parse('$root/highlights/public');
      try {
        final resp = await http.get(uri).timeout(_timeout);
        if (resp.statusCode == 200) {
          _workingApiRoot = root;
          if (resp.body.isEmpty) return [];
          final decoded = jsonDecode(resp.body);
          if (decoded is! List) return [];
          return decoded
              .map((e) => HighlightItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
        lastError = Exception('Highlights feed failed (${resp.statusCode})');
      } on SocketException {
        lastError = Exception('Network unreachable on $root');
      } on TimeoutException {
        lastError = Exception('Highlights request timed out');
      } catch (e) {
        lastError = Exception(e.toString());
      }
    }
    throw lastError ?? Exception('Unable to load highlights');
  }
}
