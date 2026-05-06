import 'package:arena_chain_flutter/core/models/feature_leagues/leagues_models.dart';
import 'package:arena_chain_flutter/core/models/feature_tournaments/tournament_model.dart';

enum TicketStatus { VALID, USED, CANCELLED }
enum TicketCategory { STANDARD, NFT }

class TicketModel {
  final String id;
  final String ticketNumber;
  final LeagueItem? league;
  final TournamentModel? tournament;
  final String userId;
  final String userName;
  final TicketCategory category;
  final TicketStatus status;
  final double price;
  final String? qrCode;
  final String type;
  final DateTime purchaseDate;
  final DateTime? usedAt;
  final String? nftTokenId;
  final String? transactionHash;

  TicketModel({
    required this.id,
    required this.ticketNumber,
    this.league,
    this.tournament,
    required this.userId,
    required this.userName,
    required this.category,
    required this.status,
    required this.price,
    this.qrCode,
    required this.type,
    required this.purchaseDate,
    this.usedAt,
    this.nftTokenId,
    this.transactionHash,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['_id'] ?? '',
      ticketNumber: json['ticketNumber'] ?? '',
      league: json['league'] != null && json['league'] is Map
          ? LeagueItem.fromJson(json['league'])
          : null,
      tournament: json['tournament'] != null && json['tournament'] is Map
          ? TournamentModel.fromJson(json['tournament'])
          : null,
      userId: json['user'] is String ? json['user'] : (json['user']?['_id'] ?? ''),
      userName: json['user'] is Map ? (json['user']['nickname'] ?? json['user']['username'] ?? json['user']['email'] ?? 'Unknown User') : 'Unknown User',
      category: _parseCategory(json['category']),
      status: _parseStatus(json['status']),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      qrCode: json['qrCode'],
      type: json['type'] ?? 'Ticket',
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'])
          : DateTime.now(),
      usedAt: json['usedAt'] != null ? DateTime.parse(json['usedAt']) : null,
      nftTokenId: json['nftTokenId']?.toString(),
      transactionHash: json['transactionHash'],
    );
  }

  static TicketCategory _parseCategory(dynamic cat) {
    if (cat == 'NFT') return TicketCategory.NFT;
    return TicketCategory.STANDARD;
  }

  static TicketStatus _parseStatus(dynamic stat) {
    if (stat == null) return TicketStatus.VALID;
    final s = stat.toString().trim().toUpperCase();
    if (s == 'USED' ||
        s == 'CHECKED_IN' ||
        s == 'CHECKEDIN' ||
        s == 'REDEEMED') {
      return TicketStatus.USED;
    }
    if (s == 'CANCELLED' || s == 'CANCELED') {
      return TicketStatus.CANCELLED;
    }
    return TicketStatus.VALID;
  }
}
