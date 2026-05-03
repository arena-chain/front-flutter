import 'package:flutter/foundation.dart';

import 'package:arena_chain_flutter/core/api/feature_highlights/highlights_feed_api.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';

class HighlightsFeedViewModel extends ChangeNotifier {
  HighlightsFeedViewModel({HighlightsFeedApi? api}) : _api = api ?? HighlightsFeedApi();

  final HighlightsFeedApi _api;

  bool isLoading = false;
  String? error;
  List<HighlightItem> items = [];

  /// Serializes [load] so a tab-triggered `load(refresh: true)` and the reels
  /// screen bootstrap never skip each other while `_inFlight` would have
  /// short-circuited the second call.
  Future<void> _loadSerial = Future<void>.value();

  /// [refresh] true: pull-to-refresh — does not show full-screen blocking spinner if we already have rows.
  Future<void> load({bool refresh = false}) async {
    _loadSerial = _loadSerial.then((_) => _performLoad(refresh: refresh));
    await _loadSerial;
  }

  Future<void> _performLoad({required bool refresh}) async {
    final showBlockingSpinner = !refresh && items.isEmpty;
    if (showBlockingSpinner) {
      isLoading = true;
      error = null;
      notifyListeners();
    } else if (refresh) {
      error = null;
    }
    try {
      items = await _api.fetchPublicHighlights();
      error = null;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
