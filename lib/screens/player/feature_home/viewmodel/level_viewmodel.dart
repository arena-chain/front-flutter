import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/level_api.dart';
import 'package:arena_chain_flutter/core/models/level_model.dart';

class LevelViewModel extends ChangeNotifier {
  final LevelApi _levelApi = LevelApi();
  PlayerLevel? _currentLevel;
  bool _isLoading = false;

  PlayerLevel? get currentLevel => _currentLevel;
  bool get isLoading => _isLoading;

  Future<void> fetchMyLevel() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentLevel = await _levelApi.getMyLevel();
    } catch (e) {
      debugPrint('Error fetching level: $e');
      // Inject default starting data on failure (matches fresh web profile)
      _currentLevel = PlayerLevel(
        level: 1,
        xp: 0,
        xpToNextLevel: 1000,
        progressPct: 0.0,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
