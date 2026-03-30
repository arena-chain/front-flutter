import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/league_api.dart';
import 'package:arena_chain_flutter/core/models/league_model.dart';

class LeagueViewModel extends ChangeNotifier {
  final LeagueApi _leagueApi = LeagueApi();
  List<League> _leagues = [];
  bool _isLoading = false;

  List<League> get leagues => _leagues;
  bool get isLoading => _isLoading;

  Future<void> fetchLeagues() async {
    _isLoading = true;
    notifyListeners();
    try {
      _leagues = await _leagueApi.getAllLeagues();
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
