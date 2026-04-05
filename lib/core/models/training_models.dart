// lib/core/models/training_models.dart

class TrainingResult {
  final String userId;
  final String difficulty; // EASY, MEDIUM, HARD
  final int score;
  final double accuracy;
  final double shotsPerSecond;
  final double avgResponseTime;
  final int duration; // seconds
  final int totalShots;
  final int hits;
  final int misses;
  final int maxCombo;

  const TrainingResult({
    required this.userId,
    required this.difficulty,
    required this.score,
    required this.accuracy,
    required this.shotsPerSecond,
    required this.avgResponseTime,
    required this.duration,
    required this.totalShots,
    required this.hits,
    required this.misses,
    required this.maxCombo,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'difficulty': difficulty,
        'score': score,
        'accuracy': accuracy,
        'shotsPerSecond': shotsPerSecond,
        'avgResponseTime': avgResponseTime,
        'duration': duration,
        'totalShots': totalShots,
        'hits': hits,
        'misses': misses,
        'maxCombo': maxCombo,
      };
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String? avatar;
  final String difficulty;
  final int score;
  final double accuracy;
  final double shotsPerSecond;
  final double avgResponseTime;
  final int duration;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    this.avatar,
    required this.difficulty,
    required this.score,
    required this.accuracy,
    required this.shotsPerSecond,
    required this.avgResponseTime,
    required this.duration,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int? ?? 0,
      userId: json['userId']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Unknown',
      avatar: json['avatar']?.toString(),
      difficulty: json['difficulty']?.toString() ?? 'MEDIUM',
      score: (json['score'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      shotsPerSecond: (json['shotsPerSecond'] as num?)?.toDouble() ?? 0.0,
      avgResponseTime: (json['avgResponseTime'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.toInt() ?? 60,
    );
  }
}

class PersonalStats {
  final List<PersonalBest> personalBests;
  final int? globalRank;
  final List<RecentSession> recentSessions;

  const PersonalStats({
    required this.personalBests,
    this.globalRank,
    required this.recentSessions,
  });

  factory PersonalStats.fromJson(Map<String, dynamic> json) {
    return PersonalStats(
      personalBests: (json['personalBests'] as List<dynamic>? ?? [])
          .map((e) => PersonalBest.fromJson(e as Map<String, dynamic>))
          .toList(),
      globalRank: json['globalRank'] as int?,
      recentSessions: (json['recentSessions'] as List<dynamic>? ?? [])
          .map((e) => RecentSession.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PersonalBest {
  final int duration;
  final int bestScore;
  final double bestAccuracy;
  final double bestShotsPerSecond;
  final double bestResponseTime;
  final int totalSessions;

  const PersonalBest({
    required this.duration,
    required this.bestScore,
    required this.bestAccuracy,
    required this.bestShotsPerSecond,
    required this.bestResponseTime,
    required this.totalSessions,
  });

  factory PersonalBest.fromJson(Map<String, dynamic> json) {
    return PersonalBest(
      duration: (json['duration'] as num?)?.toInt() ?? 60,
      bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
      bestAccuracy: (json['bestAccuracy'] as num?)?.toDouble() ?? 0.0,
      bestShotsPerSecond: (json['bestShotsPerSecond'] as num?)?.toDouble() ?? 0.0,
      bestResponseTime: (json['bestResponseTime'] as num?)?.toDouble() ?? 0.0,
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
    );
  }
}

class RecentSession {
  final int score;
  final double accuracy;
  final double shotsPerSecond;
  final double avgResponseTime;
  final int duration;
  final DateTime? createdAt;

  const RecentSession({
    required this.score,
    required this.accuracy,
    required this.shotsPerSecond,
    required this.avgResponseTime,
    required this.duration,
    this.createdAt,
  });

  factory RecentSession.fromJson(Map<String, dynamic> json) {
    return RecentSession(
      score: (json['score'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      shotsPerSecond: (json['shotsPerSecond'] as num?)?.toDouble() ?? 0.0,
      avgResponseTime: (json['avgResponseTime'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.toInt() ?? 60,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
