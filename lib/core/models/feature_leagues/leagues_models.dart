// Models for the player-facing leagues feature.

class LeagueItem {
  final String id;
  final Map<String, dynamic> raw;

  LeagueItem({required this.id, required this.raw});

  String get name => (raw['name'] ?? '').toString();
  String get status => (raw['status'] ?? 'UPCOMING').toString();
  String get level => (raw['level'] ?? 'REGIONAL').toString();
  String? get gameTitle {
    final g = raw['gameId'];
    if (g is Map) return (g['title'] ?? g['name'])?.toString();
    return raw['gameName']?.toString() ?? raw['game']?.toString();
  }
  String get regionValue => (raw['regionValue'] ?? raw['region'] ?? '').toString();
  int get participantCount {
    if (raw['participants'] is List) return (raw['participants'] as List).length;
    return (raw['participantCount'] as num?)?.toInt() ?? 0;
  }

  factory LeagueItem.fromJson(Map<String, dynamic> json) => LeagueItem(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        raw: Map<String, dynamic>.from(json),
      );
}

class SeasonItem {
  final String id;
  final Map<String, dynamic> raw;

  SeasonItem({required this.id, required this.raw});

  String get name => (raw['name'] ?? 'Season').toString();
  String get status => (raw['status'] ?? 'PLANNED').toString();
  String? get startDate => raw['startDate']?.toString();
  String? get endDate => raw['endDate']?.toString();
  String? get registrationDeadline => raw['registrationDeadline']?.toString();

  factory SeasonItem.fromJson(Map<String, dynamic> json) => SeasonItem(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        raw: Map<String, dynamic>.from(json),
      );
}

class MatchItem {
  final String id;
  final Map<String, dynamic> raw;

  MatchItem({required this.id, required this.raw});

  String get status => (raw['status'] ?? 'SCHEDULED').toString();
  String? get scheduledStart => raw['scheduledStart']?.toString();
  String? get streamId => (raw['streamId'] ?? raw['liveStreamId'])?.toString();
  String? get playbackUrl => (raw['playbackUrl'] ?? raw['streamUrl'] ?? raw['liveUrl'])?.toString();

  bool get isLive => status.toUpperCase() == 'ONGOING';
  bool get isCompleted =>
      status.toUpperCase() == 'COMPLETED' || status.toUpperCase() == 'FORFEIT';
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';

  String get team1Name {
    final t = raw['team1Id'];
    if (t is Map) return (t['name'] ?? 'Team 1').toString();
    return 'Team 1';
  }

  String get team2Name {
    final t = raw['team2Id'];
    if (t is Map) return (t['name'] ?? 'Team 2').toString();
    return 'Team 2';
  }

  int get team1GamesWon => (raw['team1GamesWon'] as num?)?.toInt() ?? 0;
  int get team2GamesWon => (raw['team2GamesWon'] as num?)?.toInt() ?? 0;

  DateTime? get scheduledDateTime {
    if (scheduledStart == null) return null;
    return DateTime.tryParse(scheduledStart!);
  }

  factory MatchItem.fromJson(Map<String, dynamic> json) => MatchItem(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        raw: Map<String, dynamic>.from(json),
      );
}

class StandingItem {
  final String id;
  final Map<String, dynamic> raw;

  StandingItem({required this.id, required this.raw});

  int get rank => (raw['rank'] as num?)?.toInt() ?? 0;
  String get teamName {
    final t = raw['teamId'];
    if (t is Map) return (t['name'] ?? 'Unknown').toString();
    return (raw['teamName'] ?? 'Unknown').toString();
  }
  int get played => (raw['played'] as num?)?.toInt() ?? 0;
  int get wins => (raw['wins'] as num?)?.toInt() ?? 0;
  int get losses => (raw['losses'] as num?)?.toInt() ?? 0;
  int get draws => (raw['draws'] as num?)?.toInt() ?? 0;
  int get forfeits => (raw['forfeits'] as num?)?.toInt() ?? 0;
  int get points => (raw['points'] as num?)?.toInt() ?? 0;
  int get gameDiff => (raw['gameDiff'] as num?)?.toInt() ?? 0;

  factory StandingItem.fromJson(Map<String, dynamic> json) {
    final teamId = json['teamId'];
    final idStr = teamId is Map
        ? (teamId['_id'] ?? teamId['id'] ?? '').toString()
        : (json['_id'] ?? json['id'] ?? '').toString();
    return StandingItem(
      id: idStr,
      raw: Map<String, dynamic>.from(json),
    );
  }
}
