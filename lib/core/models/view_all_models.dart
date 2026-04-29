/// Models for the "view all" list endpoints (players use shared scouter types).

class LeagueModel {
  final String id;
  final String name;
  final Map<String, dynamic> raw;

  LeagueModel({
    required this.id,
    required this.name,
    required this.raw,
  });

  String get level => (raw['level'] ?? raw['tier'] ?? 'REGIONAL').toString();
  bool get isActive => raw['isActive'] == true || (raw['status']?.toString().toUpperCase() == 'ACTIVE');
  String? get organiserNickname {
    final o = raw['organiserId'] ?? raw['organiser'] ?? raw['createdBy'];
    if (o is Map) return (o['nickname'] ?? o['displayName'] ?? o['name'])?.toString();
    return null;
  }
  String get regionId => (raw['regionId'] ?? raw['region'] ?? '').toString();
  String? get description => raw['description']?.toString();

  factory LeagueModel.fromJson(Map<String, dynamic> json) {
    return LeagueModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      raw: Map<String, dynamic>.from(json),
    );
  }
}

class TournamentListItem {
  final String id;
  final String name;
  final Map<String, dynamic> raw;

  TournamentListItem({
    required this.id,
    required this.name,
    required this.raw,
  });

  String get status => (raw['status'] ?? 'DRAFT').toString();
  String? get startDate => raw['startDate']?.toString() ?? raw['start']?.toString();
  String? get endDate => raw['endDate']?.toString() ?? raw['end']?.toString();
  String? get gameTitle {
    final g = raw['gameId'] ?? raw['game'];
    if (g is Map) return (g['title'] ?? g['name'])?.toString();
    if (g is String && g.isNotEmpty) return g;
    return raw['gameTitle']?.toString();
  }
  String get format => (raw['format'] ?? raw['tournamentFormat'] ?? 'SINGLE_ELIMINATION').toString();
  bool get registrationOpen => raw['registrationOpen'] == true || (raw['status']?.toString().toUpperCase() == 'OPEN_REGISTRATION');
  int get currentTeams => (raw['currentTeams'] as num?)?.toInt() ?? (raw['teams'] is List ? (raw['teams'] as List).length : 0);
  int get maxTeams => (raw['maxTeams'] as num?)?.toInt() ?? (raw['maxParticipants'] as num?)?.toInt() ?? 0;
  int get prizePool {
    final p = raw['prizePool'] ?? raw['prizes']?['total'];
    return (p as num?)?.toInt() ?? 0;
  }
  int get firstPlace {
    final f = raw['firstPlace'] ?? raw['prizes']?['first'] ?? raw['prizes']?['1st'];
    return (f as num?)?.toInt() ?? 0;
  }
  String? get description => raw['description']?.toString();

  factory TournamentListItem.fromJson(Map<String, dynamic> json) {
    return TournamentListItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      raw: Map<String, dynamic>.from(json),
    );
  }
}
