class Team {
  final String id;
  final String name;
  final int score;
  final String? teamManagerId;
  final String? photo;
  final List<String> scouts;
  final String type;
  final bool isVerified;

  Team({
    required this.id,
    required this.name,
    required this.score,
    this.teamManagerId,
    this.photo,
    required this.scouts,
    required this.type,
    required this.isVerified,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      score: json['score'] ?? 0,
      teamManagerId: json['teamManager'] is Map ? json['teamManager']['_id'] : json['teamManager'],
      photo: json['photo'],
      scouts: List<String>.from(json['scouts'] ?? []),
      type: json['type'] ?? 'amateur',
      isVerified: json['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'score': score,
      'teamManager': teamManagerId,
      'photo': photo,
      'scouts': scouts,
      'type': type,
      'isVerified': isVerified,
    };
  }
}
