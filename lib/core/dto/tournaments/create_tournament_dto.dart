class CreateTournamentDto {
  final String name;
  final String gameId;
  final String type; // 'OFFICIAL' or 'RANKED'
  final String format; // SINGLE_ELIMINATION, DOUBLE_ELIMINATION, SWISS, ROUND_ROBIN
  final DateTime startDate;
  final DateTime endDate;
  final int maxTeams;
  final String? prizePool;
  final String organizerId;
  final List<String>? invitedUserIds;

  CreateTournamentDto({
    required this.name,
    required this.gameId,
    required this.type,
    required this.format,
    required this.startDate,
    required this.endDate,
    required this.maxTeams,
    this.prizePool,
    required this.organizerId,
    this.invitedUserIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gameId': gameId,
      'type': type,
      'format': format,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'maxTeams': maxTeams,
      'prizePool': prizePool,
      'organizerId': organizerId,
      if (invitedUserIds != null && invitedUserIds!.isNotEmpty)
        'invitedUserIds': invitedUserIds,
    };
  }
}
