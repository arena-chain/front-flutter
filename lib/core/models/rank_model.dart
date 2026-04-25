class Rank {
  final String game;
  final int elo;
  final String tier;
  final int wins;
  final int losses;
  final DateTime updatedAt;

  Rank({
    required this.game,
    required this.elo,
    required this.tier,
    required this.wins,
    required this.losses,
    required this.updatedAt,
  });

  factory Rank.fromJson(Map<String, dynamic> json) {
    return Rank(
      game: json['game'] ?? '',
      elo: json['elo'] ?? 0,
      tier: json['tier'] ?? 'Unranked',
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
