class PlayerProfile {
  final String userId;
  final bool isPro;
  final bool isVerified;
  final int elo;
  final String rank;
  final Map<String, dynamic> stats;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PlayerProfile({
    required this.userId,
    required this.isPro,
    required this.isVerified,
    required this.elo,
    required this.rank,
    required this.stats,
    this.createdAt,
    this.updatedAt,
  });

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      userId: json['userId'] as String,
      isPro: json['isPro'] as bool,
      isVerified: json['isVerified'] as bool,
      elo: json['elo'] as int,
      rank: json['rank'] as String,
      stats: json['stats'] as Map<String, dynamic>? ?? {},
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'isPro': isPro,
      'isVerified': isVerified,
      'elo': elo,
      'rank': rank,
      'stats': stats,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
