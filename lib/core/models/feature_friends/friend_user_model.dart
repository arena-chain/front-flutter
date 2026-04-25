class FriendUser {
  final String id;
  final String nickname;
  final String email;
  final String? avatarUrl;

  FriendUser({
    required this.id,
    required this.nickname,
    required this.email,
    this.avatarUrl,
  });

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    return FriendUser(
      id: json['_id'] as String,
      nickname: json['nickname'] as String,
      email: json['email'] as String,
      avatarUrl: (json['avatarUrl'] ?? json['avatar'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nickname': nickname,
      'email': email,
      'avatarUrl': avatarUrl,
    };
  }
}
