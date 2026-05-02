class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final String category;
  final bool isRead;
  final bool resourceDeleted;
  final bool archived;
  final String? link;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.category,
    required this.isRead,
    required this.resourceDeleted,
    required this.archived,
    required this.link,
    required this.metadata,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      category: (json['category'] ?? 'system').toString(),
      isRead: json['isRead'] == true,
      resourceDeleted: json['resourceDeleted'] == true,
      archived: json['archived'] == true,
      link: json['link']?.toString(),
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? category,
    bool? isRead,
    bool? resourceDeleted,
    bool? archived,
    String? link,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      category: category ?? this.category,
      isRead: isRead ?? this.isRead,
      resourceDeleted: resourceDeleted ?? this.resourceDeleted,
      archived: archived ?? this.archived,
      link: link ?? this.link,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class NotificationPreferences {
  final bool matches;
  final bool leagues;
  final bool social;
  final bool achievements;
  final bool streams;
  final bool security;
  final bool emailEnabled;
  final bool emailMatches;
  final bool emailLeagues;
  final bool emailSocial;
  final bool emailAchievements;
  final bool emailStreams;
  final bool pushEnabled;

  const NotificationPreferences({
    required this.matches,
    required this.leagues,
    required this.social,
    required this.achievements,
    required this.streams,
    required this.security,
    required this.emailEnabled,
    required this.emailMatches,
    required this.emailLeagues,
    required this.emailSocial,
    required this.emailAchievements,
    required this.emailStreams,
    required this.pushEnabled,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    bool flag(String key, [bool fallback = true]) => json[key] == null ? fallback : json[key] == true;

    return NotificationPreferences(
      matches: flag('matches'),
      leagues: flag('leagues'),
      social: flag('social'),
      achievements: flag('achievements'),
      streams: flag('streams'),
      security: flag('security'),
      emailEnabled: flag('emailEnabled', false),
      emailMatches: flag('emailMatches', false),
      emailLeagues: flag('emailLeagues', false),
      emailSocial: flag('emailSocial', false),
      emailAchievements: flag('emailAchievements', false),
      emailStreams: flag('emailStreams', false),
      pushEnabled: flag('pushEnabled'),
    );
  }

  Map<String, dynamic> toJson() => {
        'matches': matches,
        'leagues': leagues,
        'social': social,
        'achievements': achievements,
        'streams': streams,
        'security': security,
        'emailEnabled': emailEnabled,
        'emailMatches': emailMatches,
        'emailLeagues': emailLeagues,
        'emailSocial': emailSocial,
        'emailAchievements': emailAchievements,
        'emailStreams': emailStreams,
        'pushEnabled': pushEnabled,
      };
}
