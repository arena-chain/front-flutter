/// JSON models for scouter / scouting APIs. Kept permissive so unknown backend
/// fields do not break parsing.

class GameModel {
  final String id;
  final Map<String, dynamic> raw;

  GameModel({required this.id, required this.raw});

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
  String get nickname => (raw['nickname'] ?? raw['displayName'] ?? 'Unknown').toString();
  String? get avatar => raw['avatar']?.toString() ?? raw['photo']?.toString();
  String get rank => (raw['rank'] ?? raw['tier'] ?? 'Unranked').toString();
  String get country => (raw['country'] ?? 'Unknown').toString();

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

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      raw: Map<String, dynamic>.from(json),
    );
  }
}
