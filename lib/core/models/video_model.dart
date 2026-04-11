enum VideoStatus { pending, approved, rejected, scheduled }

class Video {
  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? uploaderId;
  final String? uploaderNickname;
  final VideoStatus status;
  final int views;
  final int? duration;
  final DateTime uploadDate;
  final DateTime? scheduledDate;

  Video({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.videoUrl,
    this.uploaderId,
    this.uploaderNickname,
    required this.status,
    this.views = 0,
    this.duration,
    required this.uploadDate,
    this.scheduledDate,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    final dynamic uploader = json['uploader'];
    String? uploaderId;
    String? uploaderNickname;
    if (uploader is Map<String, dynamic>) {
      uploaderId = (uploader['_id'] ?? uploader['id'])?.toString();
      uploaderNickname =
          (uploader['nickname'] ?? uploader['displayName'] ?? uploader['username'])?.toString();
    } else if (uploader != null) {
      uploaderId = uploader.toString();
    }

    final statusRaw = (json['status'] ?? '').toString().toLowerCase();
    final status = VideoStatus.values.firstWhere(
      (value) => value.name == statusRaw,
      orElse: () => VideoStatus.approved,
    );

    DateTime parsedUploadDate;
    try {
      parsedUploadDate = DateTime.parse((json['createdAt'] ?? json['uploadDate']).toString());
    } catch (_) {
      parsedUploadDate = DateTime.now();
    }

    DateTime? parsedScheduledDate;
    if (json['scheduledDate'] != null) {
      try {
        parsedScheduledDate = DateTime.parse(json['scheduledDate'].toString());
      } catch (_) {
        parsedScheduledDate = null;
      }
    }

    return Video(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      videoUrl: json['url']?.toString() ?? json['videoUrl']?.toString(),
      uploaderId: uploaderId,
      uploaderNickname: uploaderNickname,
      status: status,
      views: int.tryParse('${json['views'] ?? 0}') ?? 0,
      duration: int.tryParse('${json['duration'] ?? ''}'),
      uploadDate: parsedUploadDate,
      scheduledDate: parsedScheduledDate,
    );
  }
}
