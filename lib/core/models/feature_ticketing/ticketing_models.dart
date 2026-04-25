import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';

// ── Ticket types must match the strings the backend uses in TicketTypeDefinition.name ──
// Backend uses free-form strings like "Standard", "VIP", "Premium", "VIP NFT"
// We map them to this enum for UI purposes.
enum TicketType {
  standard,
  premium,
  vip,
  nftVip,
}

extension TicketTypeExtension on TicketType {
  String get label {
    switch (this) {
      case TicketType.standard:
        return 'Standard';
      case TicketType.premium:
        return 'Premium';
      case TicketType.vip:
        return 'VIP';
      case TicketType.nftVip:
        return 'VIP NFT';
    }
  }

  /// The string sent to the backend as the ticket type name.
  String get backendName {
    switch (this) {
      case TicketType.standard:
        return 'Standard';
      case TicketType.premium:
        return 'Premium';
      case TicketType.vip:
        return 'VIP';
      case TicketType.nftVip:
        return 'VIP NFT';
    }
  }

  Color get color {
    switch (this) {
      case TicketType.standard:
        return const Color(0xFF8B95A5);
      case TicketType.premium:
        return const Color(0xFF4488FF);
      case TicketType.vip:
        return const Color(0xFFFFAA00);
      case TicketType.nftVip:
        return const Color(0xFF00FF00);
    }
  }

  static TicketType fromBackendName(String? name) {
    if (name == null) return TicketType.standard;
    final n = name.toLowerCase();
    if (n.contains('nft') || n.contains('vip nft')) return TicketType.nftVip;
    if (n.contains('vip')) return TicketType.vip;
    if (n.contains('premium')) return TicketType.premium;
    return TicketType.standard;
  }
}

// ── Ticket type as defined in a Tournament (from backend TicketTypeDefinition) ──
class TournamentTicketType {
  final String name;
  final double price;
  final int capacity;
  final bool isNft;
  final String? perks;
  final Map<String, dynamic>? metadata;

  const TournamentTicketType({
    required this.name,
    required this.price,
    required this.capacity,
    this.isNft = false,
    this.perks,
    this.metadata,
  });

  factory TournamentTicketType.fromJson(Map<String, dynamic> json) {
    final normalizedName = (json['name'] ??
            json['type'] ??
            json['ticketType'] ??
            json['label'] ??
            'Standard')
        .toString();
    final dynamic rawPrice = json['price'] ?? json['amount'] ?? json['cost'];
    final dynamic rawCapacity =
        json['capacity'] ?? json['maxCapacity'] ?? json['quantity'] ?? json['stock'];
    return TournamentTicketType(
      name: normalizedName,
      price: (rawPrice is num) ? rawPrice.toDouble() : 0.0,
      capacity: (rawCapacity is num) ? rawCapacity.toInt() : 0,
      isNft: (json['isNft'] == true) ||
          (json['nft'] == true) ||
          normalizedName.toLowerCase().contains('nft'),
      perks: json['perks']?.toString(),
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'capacity': capacity,
      'bundles': const [],
      'isNft': isNft,
      if (perks != null && perks!.trim().isNotEmpty) 'perks': perks,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

// ── EventModel ── maps from Tournament backend response ──────────────────────
class EventModel {
  final String id;
  final String leagueId;
  final String name;
  final String? description;
  final DateTime dateTime;
  final String location;
  final String? imageUrl;
  final int totalCapacity;
  final int remainingCapacity;

  /// Ticket types as objects (name, price, capacity)
  final List<TournamentTicketType> ticketTypesList;

  /// Convenience map: TicketType enum → price (for UI backward-compat)
  final Map<TicketType, double> prices;

  EventModel({
    required this.id,
    required this.leagueId,
    required this.name,
    this.description,
    required this.dateTime,
    required this.location,
    this.imageUrl,
    required this.totalCapacity,
    required this.remainingCapacity,
    required this.ticketTypesList,
    required this.prices,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    // Parse ticketTypes array (array of objects with name/price/capacity)
    final rawTypes = json['ticketTypes'];
    final List<TournamentTicketType> types = [];
    if (rawTypes is List) {
      for (final t in rawTypes) {
        if (t is Map<String, dynamic>) {
          types.add(TournamentTicketType.fromJson(t));
        }
      }
    }

    // Build legacy prices map for UI components that still use it
    final Map<TicketType, double> pricesMap = {
      TicketType.standard: 20.0,
      TicketType.premium: 50.0,
      TicketType.vip: 150.0,
      TicketType.nftVip: 300.0,
    };
    for (final t in types) {
      final enumType = TicketTypeExtension.fromBackendName(t.name);
      pricesMap[enumType] = t.price;
    }

    // Total capacity = sum of all ticket type capacities
    final int totalCap = types.isNotEmpty
        ? types.fold(0, (sum, t) => sum + t.capacity)
        : (json['totalCapacity'] as num?)?.toInt() ?? 100;

    return EventModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      leagueId: json['leagueId'] as String? ?? '',
      name: json['name'] as String? ?? 'Upcoming Tournament',
      description: json['description'] as String?,
      // Backend uses 'startDate' for tournaments
      dateTime: _parseDate(json['startDate'] ?? json['dateTime']),
      location: json['location'] as String? ??
          (json['isOnline'] == true ? 'Online' : 'TBD'),
      imageUrl: _resolveImageUrl(json['bannerImageUrl']),
      totalCapacity: totalCap,
      remainingCapacity:
          (json['remainingCapacity'] as num?)?.toInt() ?? totalCap,
      ticketTypesList: types,
      prices: pricesMap,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now().add(const Duration(days: 7));
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now().add(const Duration(days: 7));
      }
    }
    return DateTime.now().add(const Duration(days: 7));
  }

  static String? _resolveImageUrl(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString();
    if (s.isEmpty) return null;
    // Local upload path → convert to full URL
    if (s.startsWith('/uploads/')) return '${ApiConfig.baseUrl}$s';
    return s;
  }
}

// ── TicketModel ── maps from backend Ticket response ──────────────────────────
class TicketModel {
  final String id;
  final String ticketNumber;
  final String userId;
  final String eventId; // tournament id
  final String eventName; // tournament name (from populated tournament)
  final DateTime eventDateTime; // tournament startDate
  final String? eventImageUrl;
  final String eventLocation;
  final TicketType type;
  final String typeRaw; // raw string from backend e.g. "VIP NFT"
  final double price;
  final String status; // 'VALID', 'USED', 'CANCELLED', 'EXPIRED'
  final String qrCode; // base64 data URL or ticket number string

  TicketModel({
    required this.id,
    required this.ticketNumber,
    required this.userId,
    required this.eventId,
    required this.eventName,
    required this.eventDateTime,
    this.eventImageUrl,
    required this.eventLocation,
    required this.type,
    required this.typeRaw,
    required this.price,
    required this.status,
    required this.qrCode,
  });

  bool get isNFT => type == TicketType.nftVip;
  bool get isValid => status == 'VALID';

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    // tournament can be a populated object or just an ObjectId string
    final tournamentRaw = json['tournament'];
    String eventId = '';
    String eventName = 'Event';
    DateTime eventDateTime = DateTime.now();
    String? eventImageUrl;
    String eventLocation = 'TBA';

    if (tournamentRaw is Map<String, dynamic>) {
      eventId = tournamentRaw['_id'] as String? ?? '';
      eventName = tournamentRaw['name'] as String? ?? 'Event';
      final startRaw = tournamentRaw['startDate'] ?? tournamentRaw['dateTime'];
      if (startRaw != null) {
        try {
          eventDateTime = DateTime.parse(startRaw.toString());
        } catch (_) {}
      }
      final imgRaw = tournamentRaw['bannerImageUrl'];
      if (imgRaw != null && imgRaw.toString().isNotEmpty) {
        final s = imgRaw.toString();
        eventImageUrl =
            s.startsWith('/uploads/') ? '${ApiConfig.baseUrl}$s' : s;
      }
      eventLocation = tournamentRaw['location'] as String? ?? 'TUNISIA';
    } else if (tournamentRaw is String) {
      eventId = tournamentRaw;
    }

    // user can be a populated object or ObjectId string
    final userRaw = json['user'];
    String userId = '';
    if (userRaw is Map<String, dynamic>) {
      userId = userRaw['_id'] as String? ?? '';
    } else if (userRaw is String) {
      userId = userRaw;
    }

    final typeRaw = json['type'] as String? ?? 'Standard';
    final ticketNum = json['ticketNumber'] as String? ?? '';

    // qrCode from backend is a base64 data URL; use it directly for QR widget
    // If it's empty, fall back to the ticket number
    final qrRaw = json['qrCode'] as String? ?? '';
    final qrCode = qrRaw.isNotEmpty ? qrRaw : ticketNum;

    return TicketModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      ticketNumber: ticketNum,
      userId: userId,
      eventId: eventId,
      eventName: eventName,
      eventDateTime: eventDateTime,
      eventImageUrl: eventImageUrl,
      eventLocation: eventLocation,
      type: TicketTypeExtension.fromBackendName(typeRaw),
      typeRaw: typeRaw,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      status: (json['status'] as String? ?? 'VALID').toUpperCase(),
      qrCode: qrCode,
    );
  }
}
