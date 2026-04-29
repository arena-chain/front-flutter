class RiotRank {
  final String queueType;
  final String tier;
  final String rank;
  final int leaguePoints;
  final int wins;
  final int losses;

  RiotRank({
    required this.queueType,
    required this.tier,
    required this.rank,
    required this.leaguePoints,
    required this.wins,
    required this.losses,
  });

  factory RiotRank.fromJson(Map<String, dynamic> json) {
    return RiotRank(
      queueType: json['queueType'] ?? '',
      tier: json['tier'] ?? '',
      rank: json['rank'] ?? '',
      leaguePoints: json['leaguePoints'] ?? 0,
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'queueType': queueType,
      'tier': tier,
      'rank': rank,
      'leaguePoints': leaguePoints,
      'wins': wins,
      'losses': losses,
    };
  }

  String get queueLabel {
    if (queueType == 'RANKED_SOLO_5x5') return 'Solo/Duo';
    if (queueType == 'RANKED_FLEX_SR') return 'Flex';
    return queueType;
  }
}

class RiotMatchModel {
  final String matchId;
  final String championName;
  final int championId;
  final int kills;
  final int deaths;
  final int assists;
  final String kda;
  final bool win;
  final int duration;
  final List<int> items;
  final String gameMode;
  final int gameCreation;

  RiotMatchModel({
    required this.matchId,
    required this.championName,
    required this.championId,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.kda,
    required this.win,
    required this.duration,
    required this.items,
    required this.gameMode,
    required this.gameCreation,
  });

  factory RiotMatchModel.fromJson(Map<String, dynamic> json) {
    return RiotMatchModel(
      matchId: json['matchId'] ?? '',
      championName: json['championName'] ?? '',
      championId: json['championId'] ?? 0,
      kills: json['kills'] ?? 0,
      deaths: json['deaths'] ?? 0,
      assists: json['assists'] ?? 0,
      kda: json['kda'] ?? '0.00:1',
      win: json['win'] ?? false,
      duration: json['duration'] ?? 0,
      items: List<int>.from(json['items'] ?? []),
      gameMode: json['gameMode'] ?? '',
      gameCreation: json['gameCreation'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'championName': championName,
      'championId': championId,
      'kills': kills,
      'deaths': deaths,
      'assists': assists,
      'kda': kda,
      'win': win,
      'duration': duration,
      'items': items,
      'gameMode': gameMode,
      'gameCreation': gameCreation,
    };
  }

  String get championIconUrl {
    return 'https://ddragon.leagueoflegends.com/cdn/16.4.1/img/champion/$championName.png';
  }

  String get durationString {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes}m ${seconds}s';
  }
}

class RiotTftMatchModel {
  final String matchId;
  final int placement;
  final int level;
  final int goldLeft;
  final int lastRound;
  final int timeEliminated;
  final List<dynamic> traits;
  final List<dynamic> units;
  final int gameCreation;
  final String queueType;

  RiotTftMatchModel({
    required this.matchId,
    required this.placement,
    required this.level,
    required this.goldLeft,
    required this.lastRound,
    required this.timeEliminated,
    required this.traits,
    required this.units,
    required this.gameCreation,
    required this.queueType,
  });

  factory RiotTftMatchModel.fromJson(Map<String, dynamic> json) {
    // Note: The backend returns detailed info directly in the list for initial load sometimes, 
    // or we might need to adjust how we parse based on the new endpoints.
    final info = json['gameInfo'] ?? {};
    final stats = json['playerStats'] ?? {};
    
    return RiotTftMatchModel(
      matchId: json['matchId'] ?? '',
      placement: stats['placement'] ?? 0,
      level: stats['level'] ?? 0,
      goldLeft: stats['goldLeft'] ?? 0,
      lastRound: stats['lastRound'] ?? 0,
      timeEliminated: stats['timeEliminated'] ?? 0,
      traits: List<dynamic>.from(stats['traits'] ?? []),
      units: List<dynamic>.from(stats['units'] ?? []),
      gameCreation: info['gameCreation'] ?? 0,
      queueType: info['queueType'] ?? 'Other',
    );
  }

  bool get isWin => placement <= 4;

  String get durationString {
    final minutes = timeEliminated ~/ 60;
    final seconds = timeEliminated % 60;
    return '${minutes}m ${seconds}s';
  }
}

class RiotAccountModel {
  final String puuid;
  final String summonerName;
  final int level;
  final int profileIconId;
  final String accountId;
  final String region;
  final List<RiotRank> ranks;
  final List<RiotMatchModel> matchHistory;

  RiotAccountModel({
    required this.puuid,
    required this.summonerName,
    required this.level,
    required this.profileIconId,
    required this.accountId,
    required this.region,
    required this.ranks,
    required this.matchHistory,
  });

  factory RiotAccountModel.fromJson(Map<String, dynamic> json) {
    return RiotAccountModel(
      puuid: json['puuid'] ?? '',
      summonerName: json['summonerName'] ?? '',
      level: json['level'] ?? 0,
      profileIconId: json['profileIconId'] ?? 0,
      accountId: json['accountId'] ?? '',
      region: json['region'] ?? '',
      ranks: (json['ranks'] as List? ?? [])
          .map((r) => RiotRank.fromJson(r as Map<String, dynamic>))
          .toList(),
      matchHistory: (json['matchHistory'] as List? ?? [])
          .map((m) => RiotMatchModel.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'puuid': puuid,
      'summonerName': summonerName,
      'level': level,
      'profileIconId': profileIconId,
      'accountId': accountId,
      'region': region,
      'ranks': ranks.map((r) => r.toJson()).toList(),
      'matchHistory': matchHistory.map((m) => m.toJson()).toList(),
    };
  }

  String get profileIconUrl {
    // Using Data Dragon CDN for profile icons
    return 'https://ddragon.leagueoflegends.com/cdn/16.4.1/img/profileicon/$profileIconId.png';
  }
}
