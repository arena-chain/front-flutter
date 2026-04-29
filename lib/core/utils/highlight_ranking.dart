import 'package:arena_chain_flutter/core/api/feature_scouter/scouter_api.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';

int _updatedMs(HighlightItem h) {
  final u = h.raw['updatedAt'] ?? h.raw['createdAt'];
  if (u is String) {
    return DateTime.tryParse(u)?.millisecondsSinceEpoch ?? 0;
  }
  return 0;
}

class _Scored {
  final HighlightItem item;
  final int score;
  _Scored(this.item, this.score);
}

/// Ranks by likes + comments + saves (same idea as web), then recency.
Future<List<HighlightItem>> rankHighlightsByEngagement(
  ScouterApi api,
  List<HighlightItem> input, {
  int maxToScore = 120,
}) async {
  if (input.isEmpty) return [];

  final byNewest = List<HighlightItem>.from(input)
    ..sort((a, b) => _updatedMs(b).compareTo(_updatedMs(a)));

  final pool = byNewest.length > maxToScore
      ? byNewest.sublist(0, maxToScore)
      : byNewest;
  final tail = byNewest.length > maxToScore
      ? byNewest.sublist(maxToScore)
      : <HighlightItem>[];

  final scored = await Future.wait(
    pool.map((h) async {
      try {
        final e = await api.getHighlightEngagement(h.id);
        final likes = (e['likeCount'] as num?)?.toInt() ?? 0;
        final comments = (e['commentCount'] as num?)?.toInt() ?? 0;
        final saves = (e['saveCount'] as num?)?.toInt() ?? 0;
        return _Scored(h, likes + comments + saves);
      } catch (_) {
        return _Scored(h, 0);
      }
    }),
  );

  scored.sort((a, b) {
    if (b.score != a.score) return b.score.compareTo(a.score);
    return _updatedMs(b.item).compareTo(_updatedMs(a.item));
  });

  return [...scored.map((s) => s.item), ...tail];
}
