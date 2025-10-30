class User {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String role;
  final Map<String, dynamic> stats;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.role,
    required this.stats,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      role: json['role'] ?? 'user',
      stats: json['stats'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'role': role,
      'stats': stats,
    };
  }
}

class DocumentModel {
  final String id;
  final String title;
  final String fileType;
  final int? fileSize;
  final String? content;
  final Map<String, dynamic>? metadata;
  final String status;
  final bool isFavorite;
  final String? summaryId;
  final DateTime createdAt;

  DocumentModel({
    required this.id,
    required this.title,
    required this.fileType,
    this.fileSize,
    this.content,
    this.metadata,
    required this.status,
    required this.isFavorite,
    this.summaryId,
    required this.createdAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      fileType: json['fileType'] ?? '',
      fileSize: json['fileSize'],
      content: json['content'],
      metadata: json['metadata'],
      status: json['status'] ?? 'uploaded',
      isFavorite: json['isFavorite'] ?? false,
      summaryId: json['summary']?['_id'] ?? json['summary'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class Summary {
  final String id;
  final String title;
  final String content;
  final List<String> keyPoints;
  final String? audioUrl;
  final int? audioDuration;
  final String status;
  final bool isFavorite;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  Summary({
    required this.id,
    required this.title,
    required this.content,
    required this.keyPoints,
    this.audioUrl,
    this.audioDuration,
    required this.status,
    required this.isFavorite,
    this.metadata,
    required this.createdAt,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      keyPoints: List<String>.from(json['keyPoints'] ?? []),
      audioUrl: json['audioUrl'],
      audioDuration: json['audioDuration'],
      status: json['status'] ?? 'generating',
      isFavorite: json['isFavorite'] ?? false,
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class Audiobook {
  final String id;
  final String title;
  final List<Chapter> chapters;
  final int duration;
  final String status;
  final int currentPosition;
  final DateTime createdAt;

  Audiobook({
    required this.id,
    required this.title,
    required this.chapters,
    required this.duration,
    required this.status,
    required this.currentPosition,
    required this.createdAt,
  });

  factory Audiobook.fromJson(Map<String, dynamic> json) {
    return Audiobook(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      chapters: (json['chapters'] as List?)
              ?.map((c) => Chapter.fromJson(c))
              .toList() ??
          [],
      duration: json['duration'] ?? 0,
      status: json['status'] ?? 'generating',
      currentPosition: json['currentPosition'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class Chapter {
  final String title;
  final String audioUrl;
  final int duration;
  final int order;
  final int startTime;

  Chapter({
    required this.title,
    required this.audioUrl,
    required this.duration,
    required this.order,
    required this.startTime,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      title: json['title'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      duration: json['duration'] ?? 0,
      order: json['order'] ?? 0,
      startTime: json['startTime'] ?? 0,
    );
  }
}
