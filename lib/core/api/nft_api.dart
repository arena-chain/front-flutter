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

  /// GET /api/nft/marketplace
  /// Retourne tous les NFTs actuellement en vente.
  Future<List<NftModel>> getMarketplace() async {
    try {
      final response = await _client.get(_uri('/nft/marketplace'));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data
            .whereType<Map<String, dynamic>>()
            .map(NftModel.fromJson)
            .toList();
      }
      debugPrint('NftApi.getMarketplace: ${response.statusCode} ${response.body}');
      throw Exception('Marketplace fetch failed (${response.statusCode})');
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
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data
            .whereType<Map<String, dynamic>>()
            .map(NftModel.fromJson)
            .toList();
      }
      debugPrint('NftApi.getMyNfts: ${response.statusCode} ${response.body}');
      throw Exception('My NFTs fetch failed (${response.statusCode})');
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
      throw Exception('Buy failed (${response.statusCode})');
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
      throw Exception('List for sale failed (${response.statusCode})');
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
      throw Exception('Unlist failed (${response.statusCode})');
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
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data
            .whereType<Map<String, dynamic>>()
            .map(NftTransaction.fromJson)
            .toList();
      }
      debugPrint(
          'NftApi.getTransactionHistory: ${response.statusCode} ${response.body}');
      throw Exception('Transaction history failed (${response.statusCode})');
    } catch (e) {
      debugPrint('NftApi.getTransactionHistory error: $e');
      rethrow;
    }
  }
}
