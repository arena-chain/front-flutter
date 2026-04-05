import 'package:arena_chain_flutter/core/api/feature_auth/auth_api.dart';

class League {
  final String id;
  final String name;
  final String game;
  final String tier;
  final String status;
  final int entryFee;
  final List<String> participants;
  final int maxParticipants;
  final DateTime startDate;
  final DateTime? endDate;
  final String? supervisedBy; // New field
  final dynamic rewards; // New field

  League({
    required this.id,
    required this.name,
    required this.game,
    required this.tier,
    required this.status,
    required this.entryFee,
    required this.participants,
    required this.maxParticipants,
    required this.startDate,
    this.endDate,
    this.supervisedBy,
    this.rewards,
  });

  factory League.fromJson(Map<String, dynamic> json) {
    return League(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      game: json['game'] ?? '',
      tier: json['tier'] ?? '',
      status: json['status'] ?? '',
      entryFee: json['entryFee'] ?? 0,
      participants: List<String>.from(json['participants'] ?? []),
      maxParticipants: json['maxParticipants'] ?? 0,
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      supervisedBy: json['supervisedBy'],
      rewards: json['rewards'],
    );
  }
}
