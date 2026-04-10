class PlayerLevel {
  final int level;
  final int xp;
  final int xpToNextLevel;
  final double progressPct;

  PlayerLevel({
    required this.level,
    required this.xp,
    required this.xpToNextLevel,
    required this.progressPct,
  });

  factory PlayerLevel.fromJson(Map<String, dynamic> json) {
    return PlayerLevel(
      level: json['level'] ?? 1,
<<<<<<< HEAD
      xp: json['currentXP'] ?? 0,
=======
      xp: json['xp'] ?? 0,
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
      xpToNextLevel: json['xpToNextLevel'] ?? 1000,
      progressPct: (json['progressPct'] ?? 0.0).toDouble(),
    );
  }
}
