class DocumentModel {
  final String id;
  final String userId;
  final String title;
  final String author;
  final String type; // 'summary' or 'audiobook'
  final String? processedText;
  final String? audioUrl;
  final int? audioDuration; // in seconds
  final List<Chapter>? chapters;
  final String status; // 'processing', 'completed', 'failed'
  final double progress; // 0.0 to 1.0
  final bool isFavorite;
  final DateTime? lastPlayed;
  final int playbackPosition; // in seconds
  final DateTime createdAt;
  final DateTime updatedAt;

  DocumentModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    required this.type,
    this.processedText,
    this.audioUrl,
    this.audioDuration,
    this.chapters,
    required this.status,
    required this.progress,
    required this.isFavorite,
    this.lastPlayed,
    required this.playbackPosition,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['user'] ?? '',
      title: json['title'] ?? 'Sin título',
      author: json['author'] ?? 'Desconocido',
      type: json['type'] ?? 'summary',
      processedText: json['processedText'],
      audioUrl: json['audioUrl'],
      audioDuration: json['audioDuration'],
      chapters: json['chapters'] != null
          ? (json['chapters'] as List)
              .map((c) => Chapter.fromJson(c))
              .toList()
          : null,
      status: json['status'] ?? 'processing',
      progress: (json['progress'] ?? 0).toDouble(),
      isFavorite: json['isFavorite'] ?? false,
      lastPlayed: json['lastPlayed'] != null
          ? DateTime.parse(json['lastPlayed'])
          : null,
      playbackPosition: json['playbackPosition'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'title': title,
      'author': author,
      'type': type,
      'processedText': processedText,
      'audioUrl': audioUrl,
      'audioDuration': audioDuration,
      'chapters': chapters?.map((c) => c.toJson()).toList(),
      'status': status,
      'progress': progress,
      'isFavorite': isFavorite,
      'lastPlayed': lastPlayed?.toIso8601String(),
      'playbackPosition': playbackPosition,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get duration {
    if (audioDuration == null) return '0 min';
    final minutes = (audioDuration! / 60).floor();
    if (minutes < 60) return '$minutes min';
    final hours = (minutes / 60).floor();
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}min';
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) return 'Hoy';
    if (difference.inDays == 1) return 'Ayer';
    if (difference.inDays < 7) return 'Hace ${difference.inDays} días';
    if (difference.inDays < 30) return 'Hace ${(difference.inDays / 7).floor()} semanas';
    return 'Hace ${(difference.inDays / 30).floor()} meses';
  }
}

class Chapter {
  final String title;
  final int startTime;
  final int endTime;

  Chapter({
    required this.title,
    required this.startTime,
    required this.endTime,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      title: json['title'] ?? '',
      startTime: json['startTime'] ?? 0,
      endTime: json['endTime'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}
