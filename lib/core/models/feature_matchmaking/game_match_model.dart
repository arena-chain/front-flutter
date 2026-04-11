class RiotAccountInfoModel {
  final int? originalIconId;
  final String? riotGameName;
  final String? riotLinkStatus;
  final String? riotPuuid;
  final String? riotRegion;
  final String? riotTagLine;

  RiotAccountInfoModel({
    this.originalIconId,
    this.riotGameName,
    this.riotLinkStatus,
    this.riotPuuid,
    this.riotRegion,
    this.riotTagLine,
  });

  factory RiotAccountInfoModel.fromJson(Map<String, dynamic> json) {
    return RiotAccountInfoModel(
      originalIconId: json['originalIconId'] as int?,
      riotGameName: json['riotGameName'] as String?,
      riotLinkStatus: json['riotLinkStatus'] as String?,
      riotPuuid: json['riotPuuid'] as String?,
      riotRegion: json['riotRegion'] as String?,
      riotTagLine: json['riotTagLine'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalIconId': originalIconId,
      'riotGameName': riotGameName,
      'riotLinkStatus': riotLinkStatus,
      'riotPuuid': riotPuuid,
      'riotRegion': riotRegion,
      'riotTagLine': riotTagLine,
    };
  }
}

class ParticipantModel {
  final String userId;
  final String team;
  final bool? accepted;
  final int elo;
  final RiotAccountInfoModel? riotAccountInfo;

  ParticipantModel({
    required this.userId,
    required this.team,
    this.accepted,
    this.elo = 1000,
    this.riotAccountInfo,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      userId: json['userId'] as String,
      team: json['team'] as String,
      accepted: json['accepted'] as bool?,
      elo: json['elo'] as int? ?? 1000,
      riotAccountInfo: json['riotAccountInfo'] != null
          ? RiotAccountInfoModel.fromJson(
              json['riotAccountInfo'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'team': team,
      'accepted': accepted,
      'elo': elo,
      'riotAccountInfo': riotAccountInfo?.toJson(),
    };
  }
}

class RoomInfoModel {
  final String roomId;
  final String? map;

  RoomInfoModel({
    required this.roomId,
    this.map,
  });

  factory RoomInfoModel.fromJson(Map<String, dynamic> json) {
    return RoomInfoModel(
      roomId: json['roomId'] as String,
      map: json['map'] as String?,
    );
  }
}

class GameMatchModel {
  final String id;
  final String status;
  final String matchType;
  final String? mode;
  final String? server;
  final String? region;
  final int numberOfParticipant;
  final bool isScheduled;
  final RoomInfoModel? roomInfo;
  final List<ParticipantModel> participants;
  final DateTime? createdAt;

  GameMatchModel({
    required this.id,
    required this.status,
    required this.matchType,
    this.mode,
    this.server,
    this.region,
    required this.numberOfParticipant,
    this.isScheduled = false,
    this.roomInfo,
    required this.participants,
    this.createdAt,
  });

  String get modeLabel {
    switch (mode) {
      case 'CUSTOM_1V1':
        return '1v1';
      case 'CUSTOM_2V2':
        return '2v2';
      case 'CUSTOM_5V5':
        return '5v5';
      default:
        return mode ?? 'Unknown';
    }
  }

  factory GameMatchModel.fromJson(Map<String, dynamic> json) {
    return GameMatchModel(
      id: json['_id'] as String? ?? json['id'] as String,
      status: json['status'] as String,
      matchType: json['match_type'] as String? ?? '',
      mode: json['mode'] as String?,
      server: json['server'] as String?,
      region: json['region'] as String?,
      numberOfParticipant: json['number_of_participant'] as int? ?? 2,
      isScheduled: json['isScheduled'] as bool? ?? false,
      roomInfo: json['roomInfo'] != null
          ? RoomInfoModel.fromJson(json['roomInfo'] as Map<String, dynamic>)
          : null,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) =>
                  ParticipantModel.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : (json['scheduled_at'] != null
              ? DateTime.tryParse(json['scheduled_at'] as String)
              : null),
    );
  }
}
