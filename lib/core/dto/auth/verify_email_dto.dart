class VerifyEmailDto {
  final String email;
  final String otp;

  VerifyEmailDto({
    required this.email,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp': otp,
    };
  }
}
