class FriendUser {
  final String id;
  final String nickname;
  final String email;

  FriendUser({
    required this.id,
    required this.nickname,
    required this.email,
  });

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    final idRaw = json['_id'] ?? json['id'];
    return FriendUser(
      id: idRaw?.toString() ?? '',
      nickname: (json['nickname'] ?? json['username'] ?? 'Player').toString(),
      email: (json['email'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nickname': nickname,
      'email': email,
    };
  }
}
