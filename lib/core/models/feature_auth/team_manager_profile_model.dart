class TeamManagerProfile {
  final String? organizationName;
  final String? firstName;
  final String? lastName;
  final String? cin;
  final int? age;
  final String? gender;
  final String? description;
  final String? phoneNumber;
  final String? teamId;
  final String? teamName;
  final String status;
  final String userId; // Added userId

  TeamManagerProfile({
    this.organizationName,
    this.firstName,
    this.lastName,
    this.cin,
    this.age,
    this.gender,
    this.description,
    this.phoneNumber,
    this.teamId,
    this.teamName,
    required this.status,
    required this.userId, // Added userId
  });

  factory TeamManagerProfile.fromJson(Map<String, dynamic> json) {
    // Extract userId - can be a populated User object or a string ID
    String? extractedUserId;
    if (json['userId'] != null) {
      if (json['userId'] is Map) {
        // userId is populated as a User object, extract _id
        extractedUserId = json['userId']['_id']?.toString();
      } else {
        // userId is just a string ID
        extractedUserId = json['userId'].toString();
      }
    }

    return TeamManagerProfile(
      organizationName: json['organizationName'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      cin: json['cin'],
      age: json['age'],
      gender: json['gender'],
      description: json['description'],
      phoneNumber: json['phoneNumber'],
      teamId: json['team'] is Map ? json['team']['_id']?.toString() : json['team']?.toString(),
      teamName: json['team'] is Map ? json['team']['name'] : null,
      status: json['status'] ?? 'pending',
      userId: extractedUserId ?? '', // Provide empty string as fallback
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organizationName': organizationName,
      'firstName': firstName,
      'lastName': lastName,
      'cin': cin,
      'age': age,
      'gender': gender,
      'description': description,
      'phoneNumber': phoneNumber,
      'team': teamId,
      'status': status,
      'userId': userId,
    };
  }
}
