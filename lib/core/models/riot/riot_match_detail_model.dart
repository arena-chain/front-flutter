class RiotMatchDetailModel {
  final Map<String, dynamic> gameInfo;
  final Map<String, dynamic> playerStats;
  final Map<String, dynamic> teamStats;

  RiotMatchDetailModel({
    required this.gameInfo,
    required this.playerStats,
    required this.teamStats,
  });

  factory RiotMatchDetailModel.fromJson(Map<String, dynamic> json) {
    return RiotMatchDetailModel(
      gameInfo: json['gameInfo'] ?? {},
      playerStats: json['playerStats'] ?? {},
      teamStats: json['teamStats'] ?? {},
    );
  }

  // Getters for specific fields
  String get queueType => gameInfo['queueType'] ?? 'Unknown';
  String get gameMode => gameInfo['gameMode'] ?? 'Unknown';
  int get duration => gameInfo['duration'] ?? 0;
  DateTime get gameCreation => DateTime.fromMillisecondsSinceEpoch(gameInfo['gameCreation'] ?? 0);

  String get durationString {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes}m ${seconds}s';
  }

  // Player Stats
  String get championName => playerStats['championName'] ?? '';
  int get kills => playerStats['kills'] ?? 0;
  int get deaths => playerStats['deaths'] ?? 0;
  int get assists => playerStats['assists'] ?? 0;
  String get kda => playerStats['kda'] ?? '0.00:1';
  int get cs => playerStats['cs'] ?? 0;
  int get gold => playerStats['gold'] ?? 0;
  int get damageDealt => playerStats['damageDealt'] ?? 0;
  int get visionScore => playerStats['visionScore'] ?? 0;
  List<int> get items => List<int>.from(playerStats['items'] ?? []);
  List<int> get spells => List<int>.from(playerStats['spells'] ?? []);
  int get primaryRune => playerStats['runes']?['primaryStyle'] ?? 0;
  int get subRune => playerStats['runes']?['subStyle'] ?? 0;

  // Team Stats
  Map<String, dynamic> get blueTeam => teamStats['blue'] ?? {};
  Map<String, dynamic> get redTeam => teamStats['red'] ?? {};
}
