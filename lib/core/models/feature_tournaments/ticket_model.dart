import 'package:arena_chain_flutter/core/models/feature_tournaments/tournament_model.dart';

class TicketModel {
  final String id;
  final String ticketNumber;
  final TournamentModel? tournament;
  final String userId;
  final String type;
  final double price;
  final String qrCode;
  final String status; // 'VALID' | 'USED' | 'CANCELLED' | 'EXPIRED'
  final DateTime purchaseDate;
  final DateTime? usedAt;

  TicketModel({
    required this.id,
    required this.ticketNumber,
    this.tournament,
    required this.userId,
    required this.type,
    required this.price,
    required this.qrCode,
    required this.status,
    required this.purchaseDate,
    this.usedAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['_id'] as String? ?? '',
      ticketNumber: json['ticketNumber'] as String? ?? '',
      tournament: json['tournament'] != null
          ? (json['tournament'] is String 
              ? null // Tournament populated ID only
              : TournamentModel.fromJson(json['tournament']))
          : null,
      userId: json['user'] is String 
          ? json['user'] 
          : (json['user']?['_id'] ?? ''),
      type: json['type'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      qrCode: json['qrCode'] as String? ?? '',
      status: json['status'] as String? ?? 'VALID',
      purchaseDate: json['purchaseDate'] != null 
          ? DateTime.parse(json['purchaseDate'])
          : DateTime.now(),
      usedAt: json['usedAt'] != null ? DateTime.parse(json['usedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'ticketNumber': ticketNumber,
      'tournament': tournament?.toJson(),
      'user': userId,
      'type': type,
      'price': price,
      'qrCode': qrCode,
      'status': status,
      'purchaseDate': purchaseDate.toIso8601String(),
      'usedAt': usedAt?.toIso8601String(),
    };
  }
}
