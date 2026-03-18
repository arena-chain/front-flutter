import 'package:flutter/foundation.dart';
import 'package:arena_chain_flutter/core/repositories/feature_scouter/scouter_repository.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';

class ScouterRecommendationsViewModel extends ChangeNotifier {
  final ScouterRepository _repo;
  final String scouterId;

  ScouterRecommendationsViewModel({
    required this.scouterId,
    ScouterRepository? repo,
  }) : _repo = repo ?? ScouterRepository();

  bool isLoading = false;
  String? error;
  List<Recommendation> recommendations = [];

  Future<void> loadRecommendations() async {
    if (scouterId.isEmpty) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      recommendations = await _repo.getMyRecommendations(scouterId);
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
