/// Models for the Players Directory + Teams feature.

class TeamItem {
  final String id;
  final Map<String, dynamic> raw;

  TeamItem({required this.id, required this.raw});

  String get name => (raw['name'] ?? raw['teamName'] ?? 'Unknown Team').toString();

  String? get logo =>
      raw['logo']?.toString() ??
      raw['avatar']?.toString() ??
      raw['logoUrl']?.toString();

  String? get organizationName {
    final o = raw['organizationId'] ?? raw['organization'];
    if (o is Map) return (o['name'] ?? o['organizationName'])?.toString();
    return raw['organizationName']?.toString();
  }

  String get tag => (raw['tag'] ?? raw['abbreviation'] ?? '').toString();

  int get playerCount {
    final p = raw['players'] ?? raw['playerIds'] ?? raw['members'];
    if (p is List) return p.length;
    return (raw['playerCount'] as num?)?.toInt() ?? 0;
  }

  String? get gameTitle {
    final g = raw['gameId'] ?? raw['game'];
    if (g is Map) return (g['title'] ?? g['name'])?.toString();
    return raw['gameTitle']?.toString() ?? raw['game']?.toString();
  }

  factory TeamItem.fromJson(Map<String, dynamic> json) {
    return TeamItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      raw: Map<String, dynamic>.from(json),
    );
  }
}

class SeasonRosterItem {
  final String id;
  final Map<String, dynamic> raw;

  SeasonRosterItem({required this.id, required this.raw});

  String get teamId {
    final t = raw['teamId'];
    if (t is Map) return (t['_id'] ?? t['id'] ?? '').toString();
    return (t ?? '').toString();
  }

  String? get teamName {
    final t = raw['teamId'];
    if (t is Map) return t['name']?.toString();
    return null;
  }

  List<Map<String, dynamic>> get players {
    final p = raw['playerIds'];
    if (p is List) {
      return p
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  List<String> get playerUserIds {
    final p = raw['playerIds'];
    if (p is List) {
      return p.map((e) {
        if (e is Map) return (e['_id'] ?? e['id'] ?? '').toString();
        return e.toString();
      }).toList();
    }
    return [];
  }

  factory SeasonRosterItem.fromJson(Map<String, dynamic> json) {
    return SeasonRosterItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      raw: Map<String, dynamic>.from(json),
    );
  }
}
