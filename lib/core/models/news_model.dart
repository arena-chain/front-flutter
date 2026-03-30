class NewsItem {
  final String id;
  final String title;
  final String content;
  final String game;
  final String? imageUrl;
  final String? url;
  final String? source;
  final DateTime publishedAt;
  final List<String> categories;

  NewsItem({
    required this.id,
    required this.title,
    required this.content,
    required this.game,
    this.imageUrl,
    this.url,
    this.source,
    required this.publishedAt,
    required this.categories,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      game: json['game'] ?? '',
      imageUrl: json['imageUrl'],
      url: json['url'],
      source: json['source'],
      publishedAt: DateTime.parse(json['publishedAt'] ?? DateTime.now().toIso8601String()),
      categories: List<String>.from(json['categories'] ?? []),
    );
  }
}

class NewsResponse {
  final List<NewsItem> news;
  final int total;
  final int page;
  final int pages;

  NewsResponse({required this.news, required this.total, required this.page, required this.pages});

  factory NewsResponse.fromJson(Map<String, dynamic> json) {
    return NewsResponse(
      news: (json['news'] as List?)?.map((n) => NewsItem.fromJson(n)).toList() ?? [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      pages: json['pages'] ?? 1,
    );
  }
}
