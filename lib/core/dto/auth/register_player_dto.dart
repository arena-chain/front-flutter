class RegisterPlayerDto {
  final String email;
  final String password;
  final String nickname;
  final bool isPro;
  final bool isVerified;

  RegisterPlayerDto({
    required this.email,
    required this.password,
    required this.nickname,
    this.isPro = false,
    this.isVerified = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'nickname': nickname,
      'isPro': isPro,
      'isVerified': isVerified,
    };
  }
}
