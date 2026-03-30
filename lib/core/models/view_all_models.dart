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

  factory TournamentListItem.fromJson(Map<String, dynamic> json) {
    return TournamentListItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      raw: Map<String, dynamic>.from(json),
    );
  }
}
