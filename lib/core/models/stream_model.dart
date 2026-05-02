import 'package:arena_chain_flutter/core/models/channel_model.dart';

class StreamModel {
  final String id;
  final String title;
  final String? description;
  final String streamerId;
  final String channelId;
  final String? streamUrl;
  final String? playbackUrl;
  final bool isLive;
  final int viewerCount;
  final List<String> tags;
  final String? thumbnailUrl;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? scheduledStartTime;
  final DateTime? scheduledEndTime;
  final Map<String, dynamic>? streamer;
  final Channel? channel;

  StreamModel({
    required this.id,
    required this.title,
    this.description,
    required this.streamerId,
    required this.channelId,
    this.streamUrl,
    this.playbackUrl,
    this.isLive = false,
    this.viewerCount = 0,
    this.tags = const [],
    this.thumbnailUrl,
    this.startedAt,
    this.endedAt,
    this.createdAt,
    this.updatedAt,
    this.scheduledStartTime,
    this.scheduledEndTime,
    this.streamer,
    this.channel,
  });

  factory StreamModel.fromJson(Map<String, dynamic> json) {
    final streamerJson = json['streamerId'];
    final channelJson = json['channelId'];

    return StreamModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      streamerId: streamerJson is Map
          ? (streamerJson['_id'] ?? '').toString()
          : (json['streamerId'] ?? '').toString(),
      channelId: channelJson is Map
          ? (channelJson['_id'] ?? '').toString()
          : (json['channelId'] ?? '').toString(),
      streamUrl: json['streamUrl']?.toString(),
      playbackUrl: json['playbackUrl']?.toString(),
      isLive: json['isLive'] ?? false,
      viewerCount: json['viewerCount'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      startedAt: _parseDate(json['startedAt']),
      endedAt: _parseDate(json['endedAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      scheduledStartTime: _parseDate(json['scheduledStartTime']),
      scheduledEndTime: _parseDate(json['scheduledEndTime']),
      streamer: streamerJson is Map<String, dynamic>
          ? streamerJson
          : streamerJson is Map
              ? Map<String, dynamic>.from(streamerJson)
              : null,
      channel: channelJson is Map
          ? Channel(
              id: (channelJson['_id'] ?? '').toString(),
              name: (channelJson['name'] ?? '').toString(),
              ownerId: (channelJson['ownerId'] ?? '').toString(),
              avatarUrl: channelJson['avatarUrl']?.toString(),
            )
          : null,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    final raw = value.toString().trim();
    if (raw.isEmpty) {
      return null;
    }

    return DateTime.tryParse(raw);
  }
}
