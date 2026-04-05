class CatalogModel {
  final String id;
  final String name;
  final String? genre;
  final String? iconUrl;
  final String? bannerUrl;
  final List<String>? roles;

  CatalogModel({
    required this.id,
    required this.name,
    this.genre,
    this.iconUrl,
    this.bannerUrl,
    this.roles,
  });

  factory CatalogModel.fromJson(Map<String, dynamic> json) {
    return CatalogModel(
      id: json['_id'] as String,
      name: json['title'] as String, // Backend uses 'title' field
      genre: json['genre'] as String?,
      iconUrl: json['iconUrl'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      roles: (json['roles'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'genre': genre,
      'iconUrl': iconUrl,
      'bannerUrl': bannerUrl,
      'roles': roles,
    };
  }
}
