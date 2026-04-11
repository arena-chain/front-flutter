class Channel {
  final String id;
  final String name;
  final String ownerId;
  final int subscriberCount;
  final String? avatarUrl;
  final String? bannerUrl;

  Channel({
    required this.id,
    required this.name,
    required this.ownerId,
    this.subscriberCount = 0,
    this.avatarUrl,
    this.bannerUrl,
  });
}
