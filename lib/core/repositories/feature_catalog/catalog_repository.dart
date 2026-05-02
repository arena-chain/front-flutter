import 'package:arena_chain_flutter/core/api/feature_catalog/catalog_api.dart';
import 'package:arena_chain_flutter/core/models/feature_catalog/catalog_model.dart';

class CatalogRepository {
  final CatalogApi _api;

  CatalogRepository({CatalogApi? api}) : _api = api ?? CatalogApi();

  Future<List<CatalogModel>> getGames() async {
    try {
      return await _api.getGames();
    } catch (e) {
      throw Exception('Failed to load games: ${e.toString()}');
    }
  }
}
