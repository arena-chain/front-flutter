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
    return FriendUser(
      id: json['_id'] as String,
      nickname: json['nickname'] as String,
      email: json['email'] as String,
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
