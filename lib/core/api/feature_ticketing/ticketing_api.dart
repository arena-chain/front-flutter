import 'dart:convert';
import 'package:arena_chain_flutter/core/api/authenticated_client.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:arena_chain_flutter/core/models/feature_ticketing/ticketing_models.dart';
import 'package:flutter/foundation.dart';

class TicketingApi {
  final AuthenticatedClient _client = AuthenticatedClient();
  final TokenStorage _tokenStorage = TokenStorage();

  // ── Decode JWT to extract user sub (userId) ────────────────────────────
  Future<String?> _getCurrentUserId() async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) return null;
      final parts = token.split('.');
      if (parts.length < 2) return null;
      String payload = parts[1];
      // Fix base64 padding
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = jsonDecode(
          utf8.decode(base64Decode(payload.replaceAll('-', '+').replaceAll('_', '/'))));
      return decoded['sub'] as String?;
    } catch (e) {
      debugPrint('TicketingApi: Failed to decode JWT: $e');
      // Fallback: try user data stored in preferences
      final userData = await _tokenStorage.getUser();
      return userData?['_id'] as String? ?? userData?['id'] as String?;
    }
  }

  // ── Fetch all tournaments (used as "events" in the Get Tickets screen) ──
  /// [leagueId] is ignored if 'all'; backend returns all tournaments regardless.
  Future<List<EventModel>> getEvents(String leagueId) async {
    final endpoints = [
      '${ApiConfig.baseUrl}/api/tournements',
      '${ApiConfig.baseUrl}/tournements',
      '${ApiConfig.baseUrl}/api/tournaments',
      '${ApiConfig.baseUrl}/tournaments',
    ];
    for (final endpoint in endpoints) {
      try {
        final response = await _client.get(Uri.parse(endpoint));
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          return data
              .map((json) => EventModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      } catch (e) {
        debugPrint('TicketingApi.getEvents endpoint error: $e');
      }
    }
    debugPrint('TicketingApi.getEvents: all endpoints failed');
    return [];
  }

  // ── Purchase a ticket ─────────────────────────────────────────────────
  /// Returns the list of created tickets (backend always returns a list).
  Future<List<TicketModel>> buyTicket(String eventId, String ticketTypeName, {String? paymentIntentId}) async {
    final userId = await _getCurrentUserId();
    if (userId == null) throw Exception('User not authenticated');

    final isNft = ticketTypeName.toLowerCase().contains('nft');
    final url = Uri.parse('${ApiConfig.baseUrl}/api/tickets');
    final body = jsonEncode({
      'tournament': eventId,
      'user': userId,
      'type': ticketTypeName, // e.g. "Standard", "VIP", "VIP NFT"
      'quantity': 1,
      if (paymentIntentId != null) 'paymentIntentId': paymentIntentId,
      if (isNft) 'mintNft': true,
      if (isNft) 'isNft': true,
    });

    final response = await _client.post(url, body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final dynamic data = jsonDecode(response.body);
      if (data is List) {
        return data
            .map((json) => TicketModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (data is Map<String, dynamic>) {
        return [TicketModel.fromJson(data)];
      }
      return [];
    } else {
      final body = response.body;
      debugPrint('TicketingApi.buyTicket error: $body');
      throw Exception(
          'Purchase failed (${response.statusCode}): ${_parseErrorMsg(body)}');
    }
  }

  // ── Get current user's tickets ─────────────────────────────────────────
  Future<List<TicketModel>> getMyTickets() async {
    final userId = await _getCurrentUserId();
    if (userId == null) return [];

    try {
      final url = Uri.parse(
          '${ApiConfig.baseUrl}/api/tickets/my-tickets?userId=$userId');
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((json) => TicketModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint('TicketingApi.getMyTickets: status ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('TicketingApi.getMyTickets: error $e');
      return [];
    }
  }

  // ── Get available ticket types for a tournament ─────────────────────────
  Future<List<TournamentTicketType>> getAvailableTickets(String tournamentId) async {
    final endpoints = [
      '${ApiConfig.baseUrl}/api/tournements/$tournamentId/available-tickets',
      '${ApiConfig.baseUrl}/tournements/$tournamentId/available-tickets',
      '${ApiConfig.baseUrl}/api/tournaments/$tournamentId/available-tickets',
      '${ApiConfig.baseUrl}/tournaments/$tournamentId/available-tickets',
      '${ApiConfig.baseUrl}/api/tournements/$tournamentId',
      '${ApiConfig.baseUrl}/tournements/$tournamentId',
      '${ApiConfig.baseUrl}/api/tournaments/$tournamentId',
      '${ApiConfig.baseUrl}/tournaments/$tournamentId',
    ];
    final merged = <String, TournamentTicketType>{};

    for (final endpoint in endpoints) {
      try {
        final response = await _client.get(Uri.parse(endpoint));
        if (response.statusCode != 200) continue;
        final dynamic payload = jsonDecode(response.body);
        final List<dynamic> raw = payload is List
            ? payload
            : (payload is Map<String, dynamic> && payload['availableTickets'] is List)
                ? payload['availableTickets'] as List<dynamic>
                : (payload is Map<String, dynamic> && payload['ticketTypes'] is List)
                    ? payload['ticketTypes'] as List<dynamic>
                    : const [];

        for (final entry in raw) {
          if (entry is! Map<String, dynamic>) continue;
          final ticket = TournamentTicketType.fromJson(entry);
          final key = ticket.name.toUpperCase();
          merged.putIfAbsent(key, () => ticket);
        }
      } catch (e) {
        debugPrint('TicketingApi.getAvailableTickets endpoint error: $e');
      }
    }

    return merged.values.toList();
  }

  Future<Map<String, dynamic>?> getTournamentById(String tournamentId) async {
    final endpoints = [
      '${ApiConfig.baseUrl}/api/tournements/$tournamentId',
      '${ApiConfig.baseUrl}/tournements/$tournamentId',
      '${ApiConfig.baseUrl}/api/tournaments/$tournamentId',
      '${ApiConfig.baseUrl}/tournaments/$tournamentId',
    ];
    for (final endpoint in endpoints) {
      try {
        final response = await _client.get(Uri.parse(endpoint));
        if (response.statusCode == 200) {
          final dynamic payload = jsonDecode(response.body);
          if (payload is Map<String, dynamic>) return payload;
        }
      } catch (e) {
        debugPrint('TicketingApi.getTournamentById endpoint error: $e');
      }
    }
    return null;
  }

  Future<bool> addTicketTypesToTournament(
      String tournamentId, List<TournamentTicketType> ticketTypes) async {
    final existingTournament = await getTournamentById(tournamentId);
    final mergedByName = <String, TournamentTicketType>{};

    if (existingTournament != null && existingTournament['ticketTypes'] is List) {
      final List<dynamic> existingRaw = existingTournament['ticketTypes'] as List<dynamic>;
      for (final entry in existingRaw) {
        if (entry is! Map<String, dynamic>) continue;
        final t = TournamentTicketType.fromJson(entry);
        final name = t.name.trim().toUpperCase();
        if (name.isEmpty) continue;
        mergedByName[name] = t;
      }
    }

    for (final t in ticketTypes) {
      final name = t.name.trim().toUpperCase();
      if (name.isEmpty) continue;
      mergedByName[name] = t;
    }

    final payload = jsonEncode({
      'ticketTypes': mergedByName.values.map((e) => e.toJson()).toList(),
    });

    final endpoints = [
      ('${ApiConfig.baseUrl}/api/tournements/$tournamentId/tickets', 'POST'),
      ('${ApiConfig.baseUrl}/api/tournements/$tournamentId', 'PATCH'),
      ('${ApiConfig.baseUrl}/tournements/$tournamentId/tickets', 'POST'),
      ('${ApiConfig.baseUrl}/tournements/$tournamentId', 'PATCH'),
      ('${ApiConfig.baseUrl}/api/tournaments/$tournamentId/tickets', 'POST'),
      ('${ApiConfig.baseUrl}/tournaments/$tournamentId/tickets', 'POST'),
    ];

    for (final endpoint in endpoints) {
      final url = Uri.parse(endpoint.$1);
      final method = endpoint.$2;
      try {
        final response = method == 'PATCH'
            ? await _client.patch(url, body: payload)
            : await _client.post(url, body: payload);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return true;
        }
      } catch (e) {
        debugPrint('TicketingApi.addTicketTypesToTournament endpoint error: $e');
      }
    }
    return false;
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  String _parseErrorMsg(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) return decoded['message']?.toString() ?? body;
    } catch (_) {}
    return body;
  }

  // ── Mock data (fallback when backend is unavailable) ───────────────────

  List<EventModel> _getMockEvents() {
    return [
      EventModel(
        id: 'evt_mock_1',
        leagueId: 'league_1',
        name: 'Grand Finals: Valorant Champions',
        description: 'Witness the ultimate tactical mastery at the heart of the circuit.',
        dateTime: DateTime.now().add(const Duration(days: 5, hours: 4)),
        location: 'Madison Square Garden, NY',
        imageUrl:
            'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&q=80&w=800',
        totalCapacity: 5000,
        remainingCapacity: 124,
        ticketTypesList: const [
          TournamentTicketType(name: 'Standard', price: 45.0, capacity: 3000),
          TournamentTicketType(name: 'Premium', price: 120.0, capacity: 1500),
          TournamentTicketType(name: 'VIP', price: 350.0, capacity: 400),
          TournamentTicketType(name: 'VIP NFT', price: 750.0, capacity: 100),
        ],
        prices: {
          TicketType.standard: 45.0,
          TicketType.premium: 120.0,
          TicketType.vip: 350.0,
          TicketType.nftVip: 750.0,
        },
      ),
      EventModel(
        id: 'evt_mock_2',
        leagueId: 'league_1',
        name: 'Semifinals: League of Legends Spring Split',
        description: 'Battle for supremacy in the ultimate esports showdown.',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        location: 'Online',
        imageUrl:
            'https://images.unsplash.com/photo-1511512578047-dfb367046420?auto=format&fit=crop&q=80&w=800',
        totalCapacity: 10000,
        remainingCapacity: 4500,
        ticketTypesList: const [
          TournamentTicketType(name: 'Standard', price: 15.0, capacity: 8000),
          TournamentTicketType(name: 'Premium', price: 35.0, capacity: 1500),
          TournamentTicketType(name: 'VIP', price: 100.0, capacity: 400),
          TournamentTicketType(name: 'VIP NFT', price: 250.0, capacity: 100),
        ],
        prices: {
          TicketType.standard: 15.0,
          TicketType.premium: 35.0,
          TicketType.vip: 100.0,
          TicketType.nftVip: 250.0,
        },
      ),
    ];
  }

  List<TicketModel> _getMockMyTickets() {
    return [
      TicketModel(
        id: 'tkt_mock_1',
        ticketNumber: 'VALORANT-TKT-8821-B4',
        userId: 'user_123',
        eventId: 'evt_mock_1',
        eventName: 'Grand Finals: Valorant Champions',
        eventDateTime: DateTime.now().add(const Duration(days: 5)),
        eventImageUrl:
            'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&q=80&w=800',
        type: TicketType.nftVip,
        typeRaw: 'VIP NFT',
        eventLocation: 'Tokyo Dome, Japan',
        price: 750.0,
        status: 'VALID',
        qrCode: 'VALORANT-TKT-8821-B4',
      ),
      TicketModel(
        id: 'tkt_mock_2',
        ticketNumber: 'LOL-TKT-2042-X9',
        userId: 'user_123',
        eventId: 'evt_mock_2',
        eventName: 'LoL Spring Split',
        eventDateTime: DateTime.now().subtract(const Duration(days: 1)),
        type: TicketType.standard,
        typeRaw: 'Standard',
        eventLocation: 'Online / Remote',
        price: 15.0,
        status: 'USED',
        qrCode: 'LOL-TKT-2042-X9',
      ),
    ];
  }
}
