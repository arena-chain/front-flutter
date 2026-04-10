class FriendUser {
  final String id;
  final String nickname;
  final String email;
<<<<<<< HEAD
  /// Matches backend User `avatar` when present (desktop search shows user cards).
  final String? avatarUrl;
=======
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056

  FriendUser({
    required this.id,
    required this.nickname,
    required this.email,
<<<<<<< HEAD
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
=======
  });

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    return FriendUser(
      id: json['_id'] as String,
      nickname: json['nickname'] as String,
      email: json['email'] as String,
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nickname': nickname,
      'email': email,
<<<<<<< HEAD
      if (avatarUrl != null) 'avatar': avatarUrl,
=======
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
    };
  }
}
