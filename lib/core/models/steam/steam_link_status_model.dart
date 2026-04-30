class SteamLinkStatusModel {
  final bool steamVerified;
  final String? steamId;
  final String? steamUsername;
  final String? steamAvatarUrl;

  const SteamLinkStatusModel({
    required this.steamVerified,
    this.steamId,
    this.steamUsername,
    this.steamAvatarUrl,
  });

  factory SteamLinkStatusModel.fromJson(Map<String, dynamic> json) {
    return SteamLinkStatusModel(
      steamVerified: json['steamVerified'] == true,
      steamId: json['steamId']?.toString(),
      steamUsername: json['steamUsername']?.toString(),
      steamAvatarUrl: json['steamAvatarUrl']?.toString(),
    );
  }
}
