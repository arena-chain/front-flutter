enum VideoStatus { pending, approved, rejected, scheduled }

class Video {
  final String id;
  final String title;
  final String? thumbnailUrl;
  final String? videoUrl;
  final VideoStatus status;
  final int views;
  final DateTime uploadDate;
  final DateTime? scheduledDate;

  Video({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    this.videoUrl,
    required this.status,
    this.views = 0,
    required this.uploadDate,
    this.scheduledDate,
  });
}
