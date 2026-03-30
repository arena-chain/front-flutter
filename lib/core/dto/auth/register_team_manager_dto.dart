class RegisterTeamManagerDto {
  final String email;
  final String password;
  final String nickname;
  final String? organizationName;
  final String? firstName;
  final String? lastName;
  final String? cin;
  final int? age;
  final String? gender;
  final String? description;
  final String? phoneNumber;
  final String? requestTeamId;

  RegisterTeamManagerDto({
    required this.email,
    required this.password,
    required this.nickname,
    this.organizationName,
    this.firstName,
    this.lastName,
    this.cin,
    this.age,
    this.gender,
    this.description,
    this.phoneNumber,
    this.requestTeamId,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'nickname': nickname,
      'organizationName': organizationName,
      'firstName': firstName,
      'lastName': lastName,
      'cin': cin,
      'age': age,
      'gender': gender,
      'description': description,
      'phoneNumber': phoneNumber,
      'teamId': requestTeamId,
    };
  }
}
