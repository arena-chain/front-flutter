import 'package:flutter/foundation.dart';
import 'package:arena_chain_flutter/core/repositories/feature_scouter/scouter_repository.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';

class ScouterReportsViewModel extends ChangeNotifier {
  final ScouterRepository _repo;
  final String scouterId;

  ScouterReportsViewModel({
    required this.scouterId,
    ScouterRepository? repo,
  }) : _repo = repo ?? ScouterRepository();

  bool isLoading = false;
  String? error;
  List<ScoutingReport> reports = [];

  Future<void> loadReports() async {
    if (scouterId.isEmpty) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      reports = await _repo.getMyReports(scouterId);
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteReport(String id) async {
    try {
      await _repo.deleteReport(id);
      reports = reports.where((r) => r.id != id).toList();
      notifyListeners();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }
}
