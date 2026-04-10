import 'package:flutter/foundation.dart';
import 'package:arena_chain_flutter/core/repositories/feature_scouter/scouter_repository.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';

/// Public pool clips ranked by reactions — for scouter dashboard / feed (mobile).
class ScouterPublicHighlightsViewModel extends ChangeNotifier {
  final ScouterRepository _repo;

  ScouterPublicHighlightsViewModel({
    ScouterRepository? repo,
  }) : _repo = repo ?? ScouterRepository();

  bool isLoading = false;
  String? error;
  List<HighlightItem> highlights = [];

  Future<void> load({int limit = 20}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      highlights = await _repo.getRankedPublicHighlights(limit: limit);
    } catch (e) {
      error = e.toString();
      highlights = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
