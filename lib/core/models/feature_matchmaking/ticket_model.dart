class TicketModel {
  final String id;
  final String game;
  final String mode;
  final String server;
  final String region;
  final int elo;
  final String status;
  final String? gameId;
  final DateTime? scheduledAt;

  TicketModel({
    required this.id,
    required this.game,
    required this.mode,
    required this.server,
    required this.region,
    required this.elo,
    required this.status,
    this.gameId,
    this.scheduledAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] as String? ?? json['_id'] as String,
      game: json['game'] as String,
      mode: json['mode'] as String,
      server: json['server'] as String? ?? json['region'] as String? ?? '',
      region: json['region'] as String? ?? 'ALL',
      elo: json['elo'] as int,
      status: json['status'] as String,
      gameId: json['gameId'] as String?,
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'game': game,
      'mode': mode,
      'server': server,
      'region': region,
      'elo': elo,
      'status': status,
      'gameId': gameId,
      'scheduledAt': scheduledAt?.toIso8601String(),
    };
  }
}
