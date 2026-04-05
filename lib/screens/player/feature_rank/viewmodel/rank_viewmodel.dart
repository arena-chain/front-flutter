import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/rank_api.dart';
import 'package:arena_chain_flutter/core/models/rank_model.dart';

class RankViewModel extends ChangeNotifier {
  final RankApi _rankApi = RankApi();
  List<Rank> _ranks = [];
  bool _isLoading = false;

  List<Rank> get ranks => _ranks;
  bool get isLoading => _isLoading;
  Rank? get primaryRank => _ranks.isNotEmpty ? _ranks.first : null;

  Future<void> fetchMyRanks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _ranks = await _rankApi.getMyRanks();
    } catch (e) {
      debugPrint('Error fetching ranks: $e');
      _ranks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
