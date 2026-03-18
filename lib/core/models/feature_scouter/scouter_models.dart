// Scouter domain models

class ScouterProfile {
  final String id;
  final String userId;
  final String level;
  final String? notes;
  final List<String> evaluatedPlayerIds;

  ScouterProfile({
    required this.id,
    required this.userId,
    required this.level,
    this.notes,
    required this.evaluatedPlayerIds,
  });

  factory ScouterProfile.fromJson(Map<String, dynamic> json) {
    return ScouterProfile(
      id: json['_id'] as String? ?? '',
      userId: _extractId(json['userId']),
      level: json['level'] as String? ?? 'REGIONAL',
      notes: json['notes'] as String?,
      evaluatedPlayerIds: (json['evaluatedPlayerIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  static String _extractId(dynamic val) {
    if (val == null) return '';
    if (val is String) return val;
    if (val is Map) return val['_id']?.toString() ?? '';
    return val.toString();
  }
}

// ─── Leaderboard ─────────────────────────────────────────────────────────────

class LeaderboardUser {
  final String id;
  final String nickname;
  final String email;
  final String? country;
  final String? region;

  LeaderboardUser({
    required this.id,
    required this.nickname,
    required this.email,
    this.country,
    this.region,
  });

  factory LeaderboardUser.fromJson(Map<String, dynamic> json) {
    return LeaderboardUser(
      id: json['_id'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      email: json['email'] as String? ?? '',
      country: json['country'] as String?,
      region: json['region'] as String?,
    );
  }
}

class LeaderboardTeam {
  final String id;
  final String name;
  final String? logo;

  LeaderboardTeam({
    required this.id,
    required this.name,
    this.logo,
  });

  factory LeaderboardTeam.fromJson(Map<String, dynamic> json) {
    return LeaderboardTeam(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      logo: json['logo'] as String?,
    );
  }
}

class LeaderboardEntry {
  final String id;
  final String? gameId;
  final LeaderboardUser? user;
  final LeaderboardTeam? team;
  final int elo;
  final String tier;
  final int? division;
  final String? region;

  LeaderboardEntry({
    required this.id,
    this.gameId,
    this.user,
    this.team,
    required this.elo,
    required this.tier,
    this.division,
    this.region,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['_id'] as String? ?? '',
      gameId: json['gameId']?.toString(),
      user: json['user'] != null
          ? LeaderboardUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      team: json['team'] != null
          ? LeaderboardTeam.fromJson(json['team'] as Map<String, dynamic>)
          : null,
      elo: (json['elo'] as num?)?.toInt() ?? 0,
      tier: json['tier'] as String? ?? 'UNKNOWN',
      division: (json['division'] as num?)?.toInt(),
      region: json['region'] as String?,
    );
  }
}

// ─── Player Detail ────────────────────────────────────────────────────────────

class PlayerDetailUser {
  final String id;
  final String nickname;
  final String email;
  final String? country;

  PlayerDetailUser({
    required this.id,
    required this.nickname,
    required this.email,
    this.country,
  });

  factory PlayerDetailUser.fromJson(Map<String, dynamic> json) {
    return PlayerDetailUser(
      id: json['_id'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      email: json['email'] as String? ?? '',
      country: json['country'] as String?,
    );
  }
}

class PlayerDetail {
  final String id;         // player-profile _id
  final String rawUserId;  // userId as plain string (fallback for navigation)
  final PlayerDetailUser? userId; // populated user object (may be null)
  final int elo;
  final String? rank;
  final String? tier;
  final String? region;
  final bool isPro;
  final Map<String, dynamic>? stats;
  final LeaderboardTeam? team;

  PlayerDetail({
    required this.id,
    this.rawUserId = '',
    this.userId,
    required this.elo,
    this.rank,
    this.tier,
    this.region,
    this.isPro = false,
    this.stats,
    this.team,
  });

  /// Returns the best available user ID for navigation / API calls.
  String get effectiveUserId => userId?.id.isNotEmpty == true
      ? userId!.id
      : rawUserId;

  factory PlayerDetail.fromJson(Map<String, dynamic> json) {
    // userId can be a populated Map OR a plain String (unpopulated reference)
    PlayerDetailUser? userObj;
    String rawId = '';
    final userField = json['userId'];
    if (userField is Map<String, dynamic>) {
      userObj = PlayerDetailUser.fromJson(userField);
      rawId = userObj.id;
    } else if (userField is String) {
      rawId = userField;
    }

    return PlayerDetail(
      id: json['_id'] as String? ?? '',
      rawUserId: rawId,
      userId: userObj,
      elo: (json['elo'] as num?)?.toInt() ?? 0,
      rank: json['rank'] as String?,
      tier: json['tier'] as String?,
      region: json['region'] as String?,
      isPro: json['isPro'] as bool? ?? false,
      stats: json['stats'] as Map<String, dynamic>?,
      team: json['teamId'] != null && json['teamId'] is Map
          ? LeaderboardTeam.fromJson(json['teamId'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ─── Match Summary ────────────────────────────────────────────────────────────

class MatchSummary {
  final String id;
  final String? roundId;
  final String? scheduledStart;
  final String? status;
  final int team1GamesWon;
  final int team2GamesWon;

  MatchSummary({
    required this.id,
    this.roundId,
    this.scheduledStart,
    this.status,
    required this.team1GamesWon,
    required this.team2GamesWon,
  });

  factory MatchSummary.fromJson(Map<String, dynamic> json) {
    return MatchSummary(
      id: json['_id'] as String? ?? '',
      roundId: json['roundId']?.toString(),
      scheduledStart: json['scheduledStart'] as String?,
      status: json['status'] as String?,
      team1GamesWon: (json['team1GamesWon'] as num?)?.toInt() ?? 0,
      team2GamesWon: (json['team2GamesWon'] as num?)?.toInt() ?? 0,
    );
  }
}

// ─── Report ───────────────────────────────────────────────────────────────────

class ScoutingReport {
  final String id;
  final String scouterId;
  final dynamic playerId; // may be string or populated object
  final String? matchId;
  final int rating;
  final String? strengths;
  final String? weaknesses;
  final String? notes;
  final String? recommendedRole;
  final String? createdAt;

  ScoutingReport({
    required this.id,
    required this.scouterId,
    required this.playerId,
    this.matchId,
    required this.rating,
    this.strengths,
    this.weaknesses,
    this.notes,
    this.recommendedRole,
    this.createdAt,
  });

  String get playerNickname {
    if (playerId is Map) {
      return (playerId as Map)['nickname']?.toString() ?? 'Unknown';
    }
    return playerId?.toString() ?? 'Unknown';
  }

  String get playerIdStr {
    if (playerId is Map) {
      return (playerId as Map)['_id']?.toString() ?? '';
    }
    return playerId?.toString() ?? '';
  }

  factory ScoutingReport.fromJson(Map<String, dynamic> json) {
    return ScoutingReport(
      id: json['_id'] as String? ?? '',
      scouterId: json['scouterId']?.toString() ?? '',
      playerId: json['playerId'],
      matchId: json['matchId']?.toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      strengths: json['strengths'] as String?,
      weaknesses: json['weaknesses'] as String?,
      notes: json['notes'] as String?,
      recommendedRole: json['recommendedRole'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scouterId': scouterId,
      'playerId': playerIdStr,
      if (matchId != null) 'matchId': matchId,
      'rating': rating,
      if (strengths != null) 'strengths': strengths,
      if (weaknesses != null) 'weaknesses': weaknesses,
      if (notes != null) 'notes': notes,
      if (recommendedRole != null) 'recommendedRole': recommendedRole,
    };
  }
}

// ─── Prospect ─────────────────────────────────────────────────────────────────

class ProspectStatus {
  final String id;
  final String playerId;      // raw ID (player profile or user ID)
  final dynamic playerIdRaw;  // may be populated object with nickname
  final String prospectLevel;
  final String? priority;
  final String? lastUpdated;

  ProspectStatus({
    required this.id,
    required this.playerId,
    this.playerIdRaw,
    required this.prospectLevel,
    this.priority,
    this.lastUpdated,
  });

  String get playerNickname {
    if (playerIdRaw is Map) {
      return (playerIdRaw as Map)['nickname']?.toString() ??
          (playerIdRaw as Map)['userId']?['nickname']?.toString() ??
          'Unknown';
    }
    return 'Player';
  }

  factory ProspectStatus.fromJson(Map<String, dynamic> json) {
    final pIdRaw = json['playerId'];
    String pId = '';
    if (pIdRaw is Map) {
      pId = pIdRaw['_id']?.toString() ?? pIdRaw['userId']?['_id']?.toString() ?? '';
    } else if (pIdRaw != null) {
      pId = pIdRaw.toString();
    }
    return ProspectStatus(
      id: json['_id'] as String? ?? '',
      playerId: pId,
      playerIdRaw: pIdRaw,
      prospectLevel: json['prospectLevel'] as String? ?? 'UNKNOWN',
      priority: json['priority'] as String?,
      lastUpdated: json['lastUpdated'] as String?,
    );
  }
}

// ─── Recommendation ───────────────────────────────────────────────────────────

class Recommendation {
  final String id;
  final String scouterId;
  final dynamic playerId;
  final dynamic organizationId;
  final String recommendationLevel;
  final String? message;
  final String status;
  final String? createdAt;

  Recommendation({
    required this.id,
    required this.scouterId,
    required this.playerId,
    required this.organizationId,
    required this.recommendationLevel,
    this.message,
    required this.status,
    this.createdAt,
  });

  String get playerNickname {
    if (playerId is Map) {
      return (playerId as Map)['nickname']?.toString() ?? 'Unknown';
    }
    return playerId?.toString() ?? 'Unknown';
  }

  String get playerIdStr {
    if (playerId is Map) return (playerId as Map)['_id']?.toString() ?? '';
    return playerId?.toString() ?? '';
  }

  String get orgName {
    if (organizationId is Map) {
      return (organizationId as Map)['name']?.toString() ?? 'Unknown Org';
    }
    return organizationId?.toString() ?? 'Unknown Org';
  }

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['_id'] as String? ?? '',
      scouterId: json['scouterId']?.toString() ?? '',
      playerId: json['playerId'],
      organizationId: json['organizationId'],
      recommendationLevel:
          json['recommendationLevel'] as String? ?? 'CONSIDER',
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['createdAt'] as String?,
    );
  }
}

// ─── Game (catalog) ───────────────────────────────────────────────────────────

class GameModel {
  final String id;
  final String title;
  final String? genre;

  GameModel({required this.id, required this.title, this.genre});

  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      genre: json['genre'] as String?,
    );
  }
}
