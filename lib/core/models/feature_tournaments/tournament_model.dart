class TournamentModel {
  final String id;
  final String name;
  final String gameId;
  final String type; // 'OFFICIAL' or 'RANKED'
  final DateTime startDate;
  final DateTime endDate;
  final int maxTeams;
  final String? prizePool;
  final String organizerId;
  final List<String> participants;
  final List<String>? invitedUserIds;
  final String status; // e.g., 'PENDING', 'ONGOING', 'COMPLETED'
  final DateTime createdAt;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final List<dynamic>? ticketTypes; // Populated ticket types or IDs
  final String? bannerImageUrl;

  TournamentModel({
    required this.id,
    required this.name,
    required this.gameId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.maxTeams,
    this.prizePool,
    required this.organizerId,
    required this.participants,
    this.invitedUserIds,
    required this.status,
    required this.createdAt,
    this.locationName,
    this.latitude,
    this.longitude,
    this.ticketTypes,
    this.bannerImageUrl,
  });

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    // Helper to extract ID from String or Map
    String getId(dynamic value) {
      if (value is String) return value;
      if (value is Map) return value['_id']?.toString() ?? value['id']?.toString() ?? '';
      return '';
    }

    // Helper to safely parse dates
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return TournamentModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      gameId: getId(json['gameId']),
      type: json['type'] as String,
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      maxTeams: json['maxTeams'] is int ? json['maxTeams'] : int.tryParse(json['maxTeams'].toString()) ?? 0,
      prizePool: json['prizePool']?.toString(),
      organizerId: getId(json['organizerId']),
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => getId(e))
              .toList() ??
          [],
      invitedUserIds: (json['invitedUserIds'] as List<dynamic>?)
          ?.map((e) => getId(e))
          .toList(),
      status: json['status'] as String? ?? 'PENDING',
      createdAt: parseDate(json['createdAt']),
      locationName: json['locationName'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      ticketTypes: json['ticketTypes'] as List<dynamic>?,
      bannerImageUrl: json['bannerImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'gameId': gameId,
      'type': type,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'maxTeams': maxTeams,
      'prizePool': prizePool,
      'organizerId': organizerId,
      'participants': participants,
      'invitedUserIds': invitedUserIds,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'ticketTypes': ticketTypes,
      'bannerImageUrl': bannerImageUrl,
    };
  }
}
