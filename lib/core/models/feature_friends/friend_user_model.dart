class FriendUser {
  final String id;
  final String nickname;
  final String email;
  /// Matches backend User `avatar` when present (desktop search shows user cards).
  final String? avatarUrl;

  FriendUser({
    required this.id,
    required this.nickname,
    required this.email,
    this.avatarUrl,
  });

  static String _mongoId(dynamic raw) {
    if (raw == null) return '';
    if (raw is String) return raw;
    if (raw is Map) {
      final oid = raw[r'$oid'];
      if (oid != null) return oid.toString();
    }
    return raw.toString();
  }

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    return FriendUser(
      id: _mongoId(json['_id'] ?? json['id']),
      nickname: (json['nickname'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      avatarUrl: json['avatar']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nickname': nickname,
      'email': email,
      if (avatarUrl != null) 'avatar': avatarUrl,
    };
  }
}
