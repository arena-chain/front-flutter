class RiotTftMatchDetailModel {
  final Map<String, dynamic> gameInfo;
  final Map<String, dynamic> playerStats;

  RiotTftMatchDetailModel({
    required this.gameInfo,
    required this.playerStats,
  });

  factory RiotTftMatchDetailModel.fromJson(Map<String, dynamic> json) {
    return RiotTftMatchDetailModel(
      gameInfo: json['gameInfo'] ?? {},
      playerStats: json['playerStats'] ?? {},
    );
  }

  // Game Info
  int get duration => gameInfo['duration'] ?? 0;
  String get queueType => gameInfo['queueType'] ?? 'Unknown';
  DateTime get gameCreation => DateTime.fromMillisecondsSinceEpoch(gameInfo['gameCreation'] ?? 0);

  String get durationString {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes}m ${seconds}s';
  }

  // Player Stats
  int get placement => playerStats['placement'] ?? 0;
  int get level => playerStats['level'] ?? 0;
  int get goldLeft => playerStats['goldLeft'] ?? 0;
  int get lastRound => playerStats['lastRound'] ?? 0;
  int get timeEliminated => playerStats['timeEliminated'] ?? 0;
  int get playersEliminated => playerStats['playersEliminated'] ?? 0;
  int get totalDamageToPlayers => playerStats['totalDamageToPlayers'] ?? 0;
  List<dynamic> get traits => List<dynamic>.from(playerStats['traits'] ?? []);
  List<dynamic> get units => List<dynamic>.from(playerStats['units'] ?? []);
}
