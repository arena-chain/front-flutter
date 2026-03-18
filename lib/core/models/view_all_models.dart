/// Lightweight models for the View All API responses.

// ─── League ───────────────────────────────────────────────────────────────────

class LeagueModel {
  final String id;
  final String name;
  final String level;
  final String regionId;
  final String gameId;
  final String? description;
  final String? logoUrl;
  final bool isActive;
  final String? organiserNickname;

  LeagueModel({
    required this.id,
    required this.name,
    required this.level,
    required this.regionId,
    required this.gameId,
    this.description,
    this.logoUrl,
    required this.isActive,
    this.organiserNickname,
  });

  factory LeagueModel.fromJson(Map<String, dynamic> j) {
    final organiser = j['organiserId'];
    return LeagueModel(
      id: j['_id'] as String? ?? '',
      name: j['name'] as String? ?? 'Unknown League',
      level: j['level'] as String? ?? 'REGIONAL',
      regionId: j['regionId'] as String? ?? '',
      gameId: j['gameId']?.toString() ?? '',
      description: j['description'] as String?,
      logoUrl: j['logoUrl'] as String?,
      isActive: j['isActive'] as bool? ?? false,
      organiserNickname: organiser is Map ? organiser['nickname'] as String? : null,
    );
  }
}

// ─── Tournament ───────────────────────────────────────────────────────────────

class TournamentListItem {
  final String id;
  final String name;
  final String? description;
  final String? gameTitle;
  final String? gameCoverUrl;
  final String format;
  final String status;
  final int prizePool;
  final int firstPlace;
  final int maxTeams;
  final int currentTeams;
  final bool registrationOpen;
  final String? startDate;
  final String? endDate;
  final String? bannerImageUrl;

  TournamentListItem({
    required this.id,
    required this.name,
    this.description,
    this.gameTitle,
    this.gameCoverUrl,
    required this.format,
    required this.status,
    required this.prizePool,
    required this.firstPlace,
    required this.maxTeams,
    required this.currentTeams,
    required this.registrationOpen,
    this.startDate,
    this.endDate,
    this.bannerImageUrl,
  });

  factory TournamentListItem.fromJson(Map<String, dynamic> j) {
    final game = j['gameId'];
    return TournamentListItem(
      id: j['_id'] as String? ?? '',
      name: j['name'] as String? ?? 'Unknown Tournament',
      description: j['description'] as String?,
      gameTitle: game is Map ? game['title'] as String? : null,
      gameCoverUrl: game is Map ? game['coverImageUrl'] as String? : null,
      format: j['format'] as String? ?? 'SINGLE_ELIMINATION',
      status: j['status'] as String? ?? 'DRAFT',
      prizePool: (j['prizePool'] as num?)?.toInt() ?? 0,
      firstPlace: (j['firstPlace'] as num?)?.toInt() ?? 0,
      maxTeams: (j['maxTeams'] as num?)?.toInt() ?? 0,
      currentTeams: (j['currentTeams'] as num?)?.toInt() ?? 0,
      registrationOpen: j['registrationOpen'] as bool? ?? false,
      startDate: j['startDate'] as String?,
      endDate: j['endDate'] as String?,
      bannerImageUrl: j['bannerImageUrl'] as String?,
    );
  }
}
