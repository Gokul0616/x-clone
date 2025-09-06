import 'user_model.dart';

enum StoryType { image, video, text }

enum StoryPrivacy { everyone, following, close_friends }

class StoryModel {
  final String id;
  final String userId;
  final StoryType type;
  final String? mediaUrl;
  final String? textContent;
  final String? backgroundColor;
  final String? fontFamily;
  final double? fontSize;
  final String? textColor;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewedBy;
  final List<StoryReaction> reactions;
  final StoryPrivacy privacy;
  final UserModel? user;
  final bool isHighlight;
  final String? highlightId;
  final List<String> mentions;
  final String? musicUrl;
  final String? musicTitle;
  final String? musicArtist;
  final List<StorySticker> stickers;
  final Map<String, dynamic>? filters;

  StoryModel({
    required this.id,
    required this.userId,
    required this.type,
    this.mediaUrl,
    this.textContent,
    this.backgroundColor,
    this.fontFamily,
    this.fontSize,
    this.textColor,
    required this.createdAt,
    required this.expiresAt,
    this.viewedBy = const [],
    this.reactions = const [],
    this.privacy = StoryPrivacy.everyone,
    this.user,
    this.isHighlight = false,
    this.highlightId,
    this.mentions = const [],
    this.musicUrl,
    this.musicTitle,
    this.musicArtist,
    this.stickers = const [],
    this.filters,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  bool get hasBeenViewedBy => viewedBy.isNotEmpty;
  
  int get viewsCount => viewedBy.length;
  
  int get reactionsCount => reactions.length;

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: StoryType.values[json['type'] ?? 0],
      mediaUrl: json['mediaUrl'],
      textContent: json['textContent'],
      backgroundColor: json['backgroundColor'],
      fontFamily: json['fontFamily'],
      fontSize: json['fontSize']?.toDouble(),
      textColor: json['textColor'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt'])
          : DateTime.now().add(const Duration(hours: 24)),
      viewedBy: List<String>.from(json['viewedBy'] ?? []),
      reactions: json['reactions'] != null
          ? (json['reactions'] as List)
              .map((r) => StoryReaction.fromJson(r))
              .toList()
          : [],
      privacy: StoryPrivacy.values[json['privacy'] ?? 0],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      isHighlight: json['isHighlight'] ?? false,
      highlightId: json['highlightId'],
      mentions: List<String>.from(json['mentions'] ?? []),
      musicUrl: json['musicUrl'],
      musicTitle: json['musicTitle'],
      musicArtist: json['musicArtist'],
      stickers: json['stickers'] != null
          ? (json['stickers'] as List)
              .map((s) => StorySticker.fromJson(s))
              .toList()
          : [],
      filters: json['filters'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.index,
      'mediaUrl': mediaUrl,
      'textContent': textContent,
      'backgroundColor': backgroundColor,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'textColor': textColor,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'viewedBy': viewedBy,
      'reactions': reactions.map((r) => r.toJson()).toList(),
      'privacy': privacy.index,
      'user': user?.toJson(),
      'isHighlight': isHighlight,
      'highlightId': highlightId,
      'mentions': mentions,
      'musicUrl': musicUrl,
      'musicTitle': musicTitle,
      'musicArtist': musicArtist,
      'stickers': stickers.map((s) => s.toJson()).toList(),
      'filters': filters,
    };
  }

  StoryModel copyWith({
    String? id,
    String? userId,
    StoryType? type,
    String? mediaUrl,
    String? textContent,
    String? backgroundColor,
    String? fontFamily,
    double? fontSize,
    String? textColor,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<String>? viewedBy,
    List<StoryReaction>? reactions,
    StoryPrivacy? privacy,
    UserModel? user,
    bool? isHighlight,
    String? highlightId,
    List<String>? mentions,
    String? musicUrl,
    String? musicTitle,
    String? musicArtist,
    List<StorySticker>? stickers,
    Map<String, dynamic>? filters,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      textContent: textContent ?? this.textContent,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewedBy: viewedBy ?? this.viewedBy,
      reactions: reactions ?? this.reactions,
      privacy: privacy ?? this.privacy,
      user: user ?? this.user,
      isHighlight: isHighlight ?? this.isHighlight,
      highlightId: highlightId ?? this.highlightId,
      mentions: mentions ?? this.mentions,
      musicUrl: musicUrl ?? this.musicUrl,
      musicTitle: musicTitle ?? this.musicTitle,
      musicArtist: musicArtist ?? this.musicArtist,
      stickers: stickers ?? this.stickers,
      filters: filters ?? this.filters,
    );
  }
}

class StoryReaction {
  final String id;
  final String userId;
  final String emoji;
  final DateTime createdAt;
  final UserModel? user;

  StoryReaction({
    required this.id,
    required this.userId,
    required this.emoji,
    required this.createdAt,
    this.user,
  });

  factory StoryReaction.fromJson(Map<String, dynamic> json) {
    return StoryReaction(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      emoji: json['emoji'] ?? '❤️',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'emoji': emoji,
      'createdAt': createdAt.toIso8601String(),
      'user': user?.toJson(),
    };
  }
}

class StorySticker {
  final String id;
  final StickerType type;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final Map<String, dynamic> data;

  StorySticker({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0.0,
    this.data = const {},
  });

  factory StorySticker.fromJson(Map<String, dynamic> json) {
    return StorySticker(
      id: json['id'] ?? '',
      type: StickerType.values[json['type'] ?? 0],
      x: json['x']?.toDouble() ?? 0.0,
      y: json['y']?.toDouble() ?? 0.0,
      width: json['width']?.toDouble() ?? 100.0,
      height: json['height']?.toDouble() ?? 100.0,
      rotation: json['rotation']?.toDouble() ?? 0.0,
      data: json['data'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': rotation,
      'data': data,
    };
  }
}

enum StickerType { emoji, gif, mention, hashtag, location, time, music, poll, question }

class StoryHighlight {
  final String id;
  final String userId;
  final String name;
  final String? coverImageUrl;
  final List<String> storyIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserModel? user;

  StoryHighlight({
    required this.id,
    required this.userId,
    required this.name,
    this.coverImageUrl,
    this.storyIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory StoryHighlight.fromJson(Map<String, dynamic> json) {
    return StoryHighlight(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      coverImageUrl: json['coverImageUrl'],
      storyIds: List<String>.from(json['storyIds'] ?? []),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'coverImageUrl': coverImageUrl,
      'storyIds': storyIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'user': user?.toJson(),
    };
  }
}