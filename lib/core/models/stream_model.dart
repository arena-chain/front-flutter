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
    this.scheduledStartTime,
    this.scheduledEndTime,
    this.streamer,
    this.channel,
  });

  factory StreamModel.fromJson(Map<String, dynamic> json) {
    return StreamModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      streamerId: json['streamerId'] is Map ? (json['streamerId']['_id'] ?? '') : (json['streamerId'] ?? ''),
      channelId: json['channelId'] is Map ? (json['channelId']['_id'] ?? '') : (json['channelId'] ?? ''),
      streamUrl: json['streamUrl'],
      playbackUrl: json['playbackUrl'],
      isLive: json['isLive'] ?? false,
      viewerCount: json['viewerCount'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      thumbnailUrl: json['thumbnailUrl'],
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      scheduledStartTime: json['scheduledStartTime'] != null ? DateTime.parse(json['scheduledStartTime']) : null,
      scheduledEndTime: json['scheduledEndTime'] != null ? DateTime.parse(json['scheduledEndTime']) : null,
      streamer: json['streamerId'] is Map ? json['streamerId'] as Map<String, dynamic> : null,
      channel: json['channelId'] is Map ? Channel(
        id: json['channelId']['_id'] ?? '',
        name: json['channelId']['name'] ?? '',
        ownerId: json['channelId']['ownerId'] ?? '',
        avatarUrl: json['channelId']['avatarUrl'],
      ) : null,
    );
  }
}
