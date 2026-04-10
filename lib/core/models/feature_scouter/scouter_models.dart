/// JSON models for scouter / scouting APIs. Kept permissive so unknown backend
/// fields do not break parsing.

// ── Lightweight nested-object helpers ─────────────────────────────────────────

class NestedUser {
  final String id;
  final String nickname;
  NestedUser({required this.id, required this.nickname});
}

class NestedTeam {
  final String name;
  NestedTeam({required this.name});
}

// ──────────────────────────────────────────────────────────────────────────────

class GameModel {
  final String id;
  final Map<String, dynamic> raw;

  GameModel({required this.id, required this.raw});

  String get title => (raw['title'] ?? raw['name'] ?? raw['gameName'] ?? id).toString();

  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      raw: Map<String, dynamic>.from(json),
    );
  }
}

class ScouterProfile {
  final String id;
  final Map<String, dynamic> raw;

  ScouterProfile({required this.id, required this.raw});

  String get level => (raw['level'] ?? raw['scouterLevel'] ?? 'REGIONAL').toString();

  List<String> get evaluatedPlayerIds {
    final list = raw['evaluatedPlayerIds'];
    if (list is List) return list.map((e) => e.toString()).toList();
    return [];
  }

  factory ScouterProfile.fromJson(Map<String, dynamic> json) {
    return ScouterProfile(
      id: (json['_id'] ?? json['id'] ?? json['userId'] ?? '').toString(),
      raw: Map<String, dynamic>.from(json),
    );
  }
}

class PlayerDetail {
  final String id;
  final Map<String, dynamic> raw;

  PlayerDetail({required this.id, required this.raw});
  
  String get userId => id;

  // Safely extract the nested populated user object (userId or user key)
  Map<String, dynamic>? get _userObj {
    for (final key in const ['userId', 'user', 'player', 'playerData']) {
      final u = raw[key];
      if (u is Map) return Map<String, dynamic>.from(u as Map);
    }
    return null;
  }

  String get nickname {
    if (raw['nickname'] != null) return raw['nickname'].toString();
    if (raw['displayName'] != null) return raw['displayName'].toString();
    if (raw['username'] != null) return raw['username'].toString();
    final u = _userObj;
    if (u != null) {
      return (u['nickname'] ?? u['displayName'] ?? u['username'] ?? u['name'] ?? 'Unknown').toString();
    }
    return 'Unknown';
  }

  String? get avatar {
    if (raw['avatar'] != null) return raw['avatar'].toString();
    if (raw['photo'] != null) return raw['photo'].toString();
    return _userObj?['avatar']?.toString();
  }

  String get rank => (raw['rank'] ?? raw['tier'] ?? 'Unranked').toString();
  String get tier => (raw['tier'] ?? raw['rank'] ?? 'UNRANKED').toString();

  String get country {
    if (raw['country'] != null && raw['country'].toString().isNotEmpty) return raw['country'].toString();
    final u = _userObj;
    if (u != null) return (u['country'] ?? 'Unknown').toString();
    return 'Unknown';
  }

  String get region {
    if (raw['region'] != null) return raw['region'].toString();
    if (raw['country'] != null) return raw['country'].toString();
    final u = _userObj;
    if (u != null && u['country'] != null) return u['country'].toString();
    return 'GLOBAL';
  }
  int get elo => (raw['elo'] as num?)?.toInt() ?? (raw['eloRating'] as num?)?.toInt() ?? 0;
  bool get isPro => raw['isPro'] == true || raw['isPro'] == 'true';
  NestedTeam? get team {
    final t = raw['team'];
    if (t is Map) return NestedTeam(name: (t['name'] ?? '').toString());
    if (t is String && t.isNotEmpty) return NestedTeam(name: t);
    return null;
  }
  Map<String, dynamic>? get stats {
    final s = raw['stats'];
    if (s is Map) return Map<String, dynamic>.from(s);
    return null;
  }
  String get effectiveUserId {
    final uid = raw['userId'];
    if (uid is String && uid.isNotEmpty) return uid;
    if (uid is Map) return (uid['_id'] ?? uid['id'] ?? '').toString();
    return id;
  }

  String get riotLinkStatus => (raw['riotLinkStatus'] ?? 'UNLINKED').toString();
  String? get riotGameName => raw['riotGameName']?.toString();
  String? get riotPuuid => raw['riotPuuid']?.toString();
  bool get isRiotLinked =>
      riotLinkStatus.toUpperCase() == 'LINKED' ||
      (riotPuuid != null && riotPuuid!.isNotEmpty);

  factory PlayerDetail.fromJson(Map<String, dynamic> json) {
    return PlayerDetail(
      id: (json['_id'] ?? json['id'] ?? json['userId'] ?? '').toString(),
      raw: Map<String, dynamic>.from(json),
    );
  }
}

class MatchSummary {
  final String id;
  final Map<String, dynamic> raw;

  MatchSummary({required this.id, required this.raw});

  String? get scheduledStart => raw['scheduledStart']?.toString() ?? raw['date']?.toString();
  String? get status => raw['status']?.toString();
  int get team1GamesWon => (raw['team1GamesWon'] as num?)?.toInt() ?? (raw['scoreTeam1'] as num?)?.toInt() ?? 0;
  int get team2GamesWon => (raw['team2GamesWon'] as num?)?.toInt() ?? (raw['scoreTeam2'] as num?)?.toInt() ?? 0;

  factory MatchSummary.fromJson(Map<String, dynamic> json) {
    return MatchSummary(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      raw: Map<String, dynamic>.from(json),
    );
  }
}

class LeaderboardEntry {
  final String id;
  final Map<String, dynamic> raw;

  LeaderboardEntry({required this.id, required this.raw});

  NestedUser? get user {
    final u = raw['user'] ?? raw['userId'] ?? raw['player'];
    if (u is Map) {
      return NestedUser(
        id: (u['_id'] ?? u['id'] ?? '').toString(),
        nickname: (u['nickname'] ?? u['displayName'] ?? '').toString(),
      );
    }
    return null;
  }
  NestedTeam? get team {
    final t = raw['team'];
    if (t is Map) return NestedTeam(name: (t['name'] ?? '').toString());
    if (t is String && t.isNotEmpty) return NestedTeam(name: t);
    return null;
  }
  String get tier => (raw['tier'] ?? raw['rank'] ?? 'UNRANKED').toString();
  int get elo => (raw['elo'] as num?)?.toInt() ?? (raw['eloRating'] as num?)?.toInt() ?? 0;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: (json['_id'] ?? json['id'] ?? json['playerId'] ?? '').toString(),
      raw: Map<String, dynamic>.from(json),
    );
  }
}

class ScoutingReport {
  final String id;
  final Map<String, dynamic> raw;

  ScoutingReport({required this.id, required this.raw});

  String get scouterId => (raw['scouterId'] ?? '').toString();
  dynamic get playerId => raw['playerId'];
  String get playerIdStr {
    final p = raw['playerId'];
    if (p is Map) return (p['_id'] ?? p['id'] ?? '').toString();
    return (p ?? '').toString();
  }
  String? get playerNickname {
    final p = raw['playerId'];
    if (p is Map) {
      final nick = p['nickname'] ?? p['displayName'] ?? p['username'];
      if (nick != null) return nick.toString();
    }
    final injected = raw['playerNickname'];
    if (injected != null && injected.toString().isNotEmpty) return injected.toString();
    return null;
  }
  String? get matchId => raw['matchId']?.toString();
  int get rating => (raw['rating'] as num?)?.toInt() ?? 0;
  String? get strengths => raw['strengths']?.toString();
  String? get weaknesses => raw['weaknesses']?.toString();
  String? get notes => raw['notes']?.toString();
  String? get recommendedRole => raw['recommendedRole']?.toString();
  String? get createdAt => raw['createdAt']?.toString();

  factory ScoutingReport.fromJson(Map<String, dynamic> json) {
    return ScoutingReport(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      raw: Map<String, dynamic>.from(json),
    );
  }
}

class ProspectStatus {
  final String id;
  final Map<String, dynamic> raw;

  ProspectStatus({required this.id, required this.raw});

  dynamic get playerIdRaw => raw['playerId'] ?? raw['player'] ?? raw['playerProfileId'];
  String get playerId {
    for (final key in const ['playerId', 'player', 'playerProfileId']) {
      final v = raw[key];
      if (v is Map) return (v['_id'] ?? v['id'] ?? '').toString();
      if (v is String && v.isNotEmpty) return v;
    }
    return id; // fall back to document _id (often the playerProfile id)
  }
  String? get playerNickname {
    for (final key in const ['playerId', 'player', 'playerProfileId']) {
      final v = raw[key];
      if (v is Map) {
        final nick = v['nickname'] ?? v['displayName'] ?? v['username'];
        if (nick != null) return nick.toString();
      }
    }
    final injected = raw['_enrichedNickname'] ?? raw['playerNickname'];
    if (injected != null && injected.toString().isNotEmpty) return injected.toString();
    return null;
  }
  String get prospectLevel => (raw['prospectLevel'] ?? 'WATCHLIST').toString();
  String? get priority => raw['priority']?.toString();
  String? get lastUpdated => raw['lastUpdated']?.toString();

  factory ProspectStatus.fromJson(Map<String, dynamic> json) {
    return ProspectStatus(
      id: (json['_id'] ?? json['id'] ?? json['playerId'] ?? '').toString(),
      raw: Map<String, dynamic>.from(json),
    );
  }
}

class Recommendation {
  final String id;
  final Map<String, dynamic> raw;

  Recommendation({required this.id, required this.raw});

  String get playerNickname {
    final p = raw['playerId'];
    if (p is Map) return (p['nickname'] ?? p['displayName'] ?? '').toString();
    return (raw['playerNickname'] ?? '').toString();
  }
  String get playerIdStr {
    final p = raw['playerId'];
    if (p is Map) return (p['_id'] ?? p['id'] ?? '').toString();
    return (p ?? '').toString();
  }
  String get orgName {
    final o = raw['orgId'] ?? raw['organization'];
    if (o is Map) return (o['name'] ?? '').toString();
    return (raw['orgName'] ?? o?.toString() ?? '').toString();
  }
  String get status => (raw['status'] ?? 'PENDING').toString();
  String get recommendationLevel => (raw['recommendationLevel'] ?? raw['level'] ?? 'RECOMMEND').toString();

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      raw: Map<String, dynamic>.from(json),
    );
  }
}

class HighlightItem {
  final String id;
  final Map<String, dynamic> raw;

  HighlightItem({required this.id, required this.raw});

  String get title {
    final v = raw['video'];
    if (v is Map) return (v['title'] ?? 'Highlight').toString();
    return (raw['title'] ?? 'Highlight').toString();
  }

  String? get videoUrl {
    final v = raw['video'];
    if (v is Map) return v['url']?.toString();
    return raw['videoUrl']?.toString();
  }

  String? get thumbnailUrl {
    final v = raw['video'];
    if (v is Map) return v['thumbnailUrl']?.toString();
    return raw['thumbnailUrl']?.toString();
  }

  String? get duration {
    final v = raw['video'];
    if (v is Map) return v['duration']?.toString();
    return null;
  }

<<<<<<< HEAD
=======
  /// Processed highlight clip URL (short vertical clip), when present.
  String? get clipUrl {
    final u = raw['clipUrl']?.toString();
    if (u != null && u.trim().isNotEmpty) return u.trim();
    return null;
  }

  /// Prefer clip for playback, else full source video URL from nested `video` or flat fields.
  String? get playableUrl => clipUrl ?? videoUrl;

>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
  String get creatorId {
    final c = raw['creator'];
    if (c is Map) return (c['_id'] ?? c['id'] ?? '').toString();
    return (c ?? '').toString();
  }

  factory HighlightItem.fromJson(Map<String, dynamic> json) {
    return HighlightItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      raw: Map<String, dynamic>.from(json),
    );
  }
}

class RankEntry {
  final String id;
  final Map<String, dynamic> raw;

  RankEntry({required this.id, required this.raw});

  String get gameTitle {
    final g = raw['gameId'];
    if (g is Map) return (g['title'] ?? g['name'] ?? '').toString();
    return (raw['gameName'] ?? raw['game'] ?? id).toString();
  }

  String get tier => (raw['tier'] ?? raw['rank'] ?? 'UNRANKED').toString();
  int get elo => (raw['elo'] as num?)?.toInt() ?? (raw['eloRating'] as num?)?.toInt() ?? 0;
  int get wins => (raw['wins'] as num?)?.toInt() ?? 0;
  int get losses => (raw['losses'] as num?)?.toInt() ?? 0;
  int get winRate {
    final total = wins + losses;
    if (total == 0) return 0;
    return ((wins / total) * 100).round();
  }

  factory RankEntry.fromJson(Map<String, dynamic> json) {
    final gameId = json['gameId'];
    final idStr = gameId is Map
        ? (gameId['_id'] ?? gameId['id'] ?? '').toString()
        : (json['_id'] ?? json['id'] ?? json['gameId'] ?? '').toString();
    return RankEntry(
      id: idStr,
      raw: Map<String, dynamic>.from(json),
    );
  }
}
