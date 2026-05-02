import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:arena_chain_flutter/core/api/authenticated_client.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:arena_chain_flutter/core/models/nft_model.dart';

/// Couche API du marketplace NFT.
/// Miroir exact des endpoints utilisés dans la version Web (`nftService.ts`).
class NftApi {
  final AuthenticatedClient _client = AuthenticatedClient();

  Uri _uri(String path, {Map<String, dynamic>? queryParams}) {
    final base = ApiConfig.baseUrl; // ex: http://192.168.1.195:3000/api
    return Uri.parse('$base$path').replace(
      queryParameters: queryParams?.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  /// Parses Nest-style `{ "message": "..." }` from error responses.
  static String? _messageFromErrorBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;
      final m = Map<String, dynamic>.from(decoded);
      final msg = m['message'] ?? m['error'];
      if (msg is String && msg.trim().isNotEmpty) return msg.trim();
    } catch (_) {}
    return null;
  }

  /// Backend may return a raw JSON array or `{ "data": [...] }` / `{ "nfts": [...] }`.
  static List<dynamic> _decodeListBody(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List) return decoded;
    if (decoded is Map) {
      final m = Map<String, dynamic>.from(decoded);
      for (final key in [
        'data',
        'nfts',
        'items',
        'results',
        'marketplace',
        'transactions',
        'history',
      ]) {
        final v = m[key];
        if (v is List) return v;
      }
    }
    throw const FormatException(
      'NFT list: expected JSON array or object with data/nfts/items',
    );
  }

  /// GET /api/nft/marketplace
  /// Retourne tous les NFTs actuellement en vente.
  Future<List<NftModel>> getMarketplace() async {
    try {
      final response = await _client.get(_uri('/nft/marketplace'));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _decodeListBody(response.body);
        return data
            .whereType<Map<String, dynamic>>()
            .map(NftModel.fromJson)
            .toList();
      }
      debugPrint('NftApi.getMarketplace: ${response.statusCode} ${response.body}');
      final detail = _messageFromErrorBody(response.body);
      throw Exception(
        detail ?? 'Marketplace fetch failed (${response.statusCode})',
      );
    } catch (e) {
      debugPrint('NftApi.getMarketplace error: $e');
      rethrow;
    }
  }

  /// GET /api/nft/my
  /// Retourne tous les NFTs possédés par l'utilisateur connecté.
  Future<List<NftModel>> getMyNfts() async {
    try {
      final response = await _client.get(_uri('/nft/my'));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _decodeListBody(response.body);
        return data
            .whereType<Map<String, dynamic>>()
            .map(NftModel.fromJson)
            .toList();
      }
      debugPrint('NftApi.getMyNfts: ${response.statusCode} ${response.body}');
      final detail = _messageFromErrorBody(response.body);
      throw Exception(detail ?? 'My NFTs fetch failed (${response.statusCode})');
    } catch (e) {
      debugPrint('NftApi.getMyNfts error: $e');
      rethrow;
    }
  }

  /// POST /api/nft/:nftItemId/buy
  /// Achète un NFT du marketplace.
  Future<NftModel> buy(String nftItemId) async {
    try {
      final response = await _client.post(_uri('/nft/$nftItemId/buy'), body: {});
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        return NftModel.fromJson(data);
      }
      debugPrint('NftApi.buy: ${response.statusCode} ${response.body}');
      throw Exception(
        _messageFromErrorBody(response.body) ?? 'Buy failed (${response.statusCode})',
      );
    } catch (e) {
      debugPrint('NftApi.buy error: $e');
      rethrow;
    }
  }

  /// POST /api/nft/:nftItemId/list
  /// Met un NFT en vente au prix donné.
  Future<NftModel> listForSale(String nftItemId, double listPrice) async {
    try {
      final response = await _client.post(
        _uri('/nft/$nftItemId/list'),
        body: {'listPrice': listPrice},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        return NftModel.fromJson(data);
      }
      debugPrint('NftApi.listForSale: ${response.statusCode} ${response.body}');
      throw Exception(
        _messageFromErrorBody(response.body) ??
            'List for sale failed (${response.statusCode})',
      );
    } catch (e) {
      debugPrint('NftApi.listForSale error: $e');
      rethrow;
    }
  }

  /// POST /api/nft/:nftItemId/unlist
  /// Retire un NFT de la vente.
  Future<NftModel> unlist(String nftItemId) async {
    try {
      final response = await _client.post(
        _uri('/nft/$nftItemId/unlist'),
        body: {},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        return NftModel.fromJson(data);
      }
      debugPrint('NftApi.unlist: ${response.statusCode} ${response.body}');
      throw Exception(
        _messageFromErrorBody(response.body) ?? 'Unlist failed (${response.statusCode})',
      );
    } catch (e) {
      debugPrint('NftApi.unlist error: $e');
      rethrow;
    }
  }

  /// GET /api/nft/transactions/history?limit=N
  /// Historique des transactions marketplace.
  Future<List<NftTransaction>> getTransactionHistory({int limit = 15}) async {
    try {
      final response = await _client.get(
        _uri('/nft/transactions/history', queryParams: {'limit': limit}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _decodeListBody(response.body);
        return data
            .whereType<Map<String, dynamic>>()
            .map(NftTransaction.fromJson)
            .toList();
      }
      debugPrint(
          'NftApi.getTransactionHistory: ${response.statusCode} ${response.body}');
      throw Exception(
        _messageFromErrorBody(response.body) ??
            'Transaction history failed (${response.statusCode})',
      );
    } catch (e) {
      debugPrint('NftApi.getTransactionHistory error: $e');
      rethrow;
    }
  }
}
