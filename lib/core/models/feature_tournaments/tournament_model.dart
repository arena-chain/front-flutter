class TournamentModel {
  final String id;
  final String name;
  final String? description;
  final String gameId;
  final String type; // 'OFFICIAL' or 'RANKED'
  final String format;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? registrationStart;
  final DateTime? registrationEnd;
  final DateTime? ticketSalesStart;
  final int maxTeams;
  final String? prizePool;
  final String? bannerImageUrl;
  final String? streamUrl;
  final bool registrationOpen;
  final String? rulesText;
  final List<TournamentPhase> phases;
  final List<TournamentTicketType> ticketTypes;
  final String organizerId;
  final List<String> participants;
  final List<String> teams;
  final List<String>? invitedUserIds;
  final String status; // e.g., 'PENDING', 'ONGOING', 'COMPLETED'
  final DateTime createdAt;
  final String? locationName;
  final double? latitude;
  final double? longitude;

  TournamentModel({
    required this.id,
    required this.name,
    this.description,
    required this.gameId,
    required this.type,
    this.format = 'UNKNOWN',
    required this.startDate,
    required this.endDate,
    this.registrationStart,
    this.registrationEnd,
    this.ticketSalesStart,
    required this.maxTeams,
    this.prizePool,
    this.bannerImageUrl,
    this.streamUrl,
    this.registrationOpen = false,
    this.rulesText,
    this.phases = const [],
    this.ticketTypes = const [],
    required this.organizerId,
    required this.participants,
    this.teams = const [],
    this.invitedUserIds,
    required this.status,
    required this.createdAt,
    this.locationName,
    this.latitude,
    this.longitude,
  });

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    // Helper to extract ID from String or Map
    String getId(dynamic value) {
      if (value is String) return value;
      if (value is Map) return value['_id']?.toString() ?? value['id']?.toString() ?? '';
      return '';
    }

    // Helper to safely parse dates
    DateTime parseDate(dynamic value, {DateTime? fallback}) {
      if (value == null) return fallback ?? DateTime.now();
      if (value is String) return DateTime.tryParse(value) ?? (fallback ?? DateTime.now());
      return fallback ?? DateTime.now();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return TournamentModel(
      id: getId(json['_id'] ?? json['id']),
      name: (json['name'] ?? 'Tournament').toString(),
      description: json['description']?.toString(),
      gameId: getId(json['gameId']),
      type: (json['type'] ?? 'OFFICIAL').toString(),
      format: (json['format'] ?? 'UNKNOWN').toString(),
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate'], fallback: parseDate(json['startDate'])),
      registrationStart: parseNullableDate(json['registrationStart']),
      registrationEnd: parseNullableDate(json['registrationEnd']),
      ticketSalesStart: parseNullableDate(json['ticketSalesStart']),
      maxTeams: json['maxTeams'] is int ? json['maxTeams'] : int.tryParse(json['maxTeams'].toString()) ?? 0,
      prizePool: json['prizePool']?.toString(),
      bannerImageUrl: json['bannerImageUrl']?.toString(),
      streamUrl: json['streamUrl']?.toString(),
      registrationOpen: json['registrationOpen'] == true,
      rulesText: json['rules']?.toString(),
      phases: (json['phases'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(TournamentPhase.fromJson)
              .toList() ??
          const [],
      ticketTypes: (json['ticketTypes'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(TournamentTicketType.fromJson)
              .toList() ??
          const [],
      organizerId: getId(json['organizerId']),
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => getId(e))
              .toList() ??
          [],
      teams: (json['teams'] as List<dynamic>?)?.map((e) => getId(e)).where((e) => e.isNotEmpty).toList() ?? const [],
      invitedUserIds: (json['invitedUserIds'] as List<dynamic>?)
          ?.map((e) => getId(e))
          .toList(),
      status: json['status'] as String? ?? 'PENDING',
      createdAt: parseDate(json['createdAt']),
      locationName: json['locationName'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'gameId': gameId,
      'type': type,
      'format': format,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'registrationStart': registrationStart?.toIso8601String(),
      'registrationEnd': registrationEnd?.toIso8601String(),
      'ticketSalesStart': ticketSalesStart?.toIso8601String(),
      'maxTeams': maxTeams,
      'prizePool': prizePool,
      'bannerImageUrl': bannerImageUrl,
      'streamUrl': streamUrl,
      'registrationOpen': registrationOpen,
      'rules': rulesText,
      'phases': phases.map((p) => p.toJson()).toList(),
      'ticketTypes': ticketTypes.map((t) => t.toJson()).toList(),
      'organizerId': organizerId,
      'participants': participants,
      'teams': teams,
      'invitedUserIds': invitedUserIds,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  int get currentTeams => participants.length;

  bool get canRegisterNow {
    if (!registrationOpen) return false;
    if (status != 'OPEN_REGISTRATION') return false;
    if (maxTeams > 0 && currentTeams >= maxTeams) return false;
    final now = DateTime.now();
    if (registrationStart != null && now.isBefore(registrationStart!)) return false;
    if (registrationEnd != null && now.isAfter(registrationEnd!)) return false;
    return true;
  }
}

class TournamentPhase {
  final String name;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int matchesCount;

  const TournamentPhase({
    required this.name,
    required this.status,
    this.startDate,
    this.endDate,
    this.matchesCount = 0,
  });

  factory TournamentPhase.fromJson(Map<String, dynamic> json) {
    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final matches = json['matches'];
    final matchCount = matches is List ? matches.length : (json['matchesCount'] as num?)?.toInt() ?? 0;
    return TournamentPhase(
      name: (json['name'] ?? 'Phase').toString(),
      status: (json['status'] ?? 'PENDING').toString(),
      startDate: parseNullableDate(json['startDate']),
      endDate: parseNullableDate(json['endDate']),
      matchesCount: matchCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'status': status,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'matchesCount': matchesCount,
      };
}

class TournamentTicketType {
  final String name;
  final String? price;

  const TournamentTicketType({required this.name, this.price});

  factory TournamentTicketType.fromJson(Map<String, dynamic> json) {
    return TournamentTicketType(
      name: (json['name'] ?? 'Ticket').toString(),
      price: json['price']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
      };
}
