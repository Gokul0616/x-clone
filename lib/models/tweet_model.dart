import 'user_model.dart';

class TweetModel {
  final String id;
  final String userId; // Still a String, but extracted from userId._id
  final String content;
  final List<String> imageUrls;
  final DateTime createdAt;
  final int likesCount;
  final int retweetsCount;
  final int repliesCount;
  final int quoteTweetsCount;
  final List<String> likedBy;
  final List<String> retweetedBy;
  final bool isRetweet;
  final String? originalTweetId;
  final String? retweetedByUserId;
  final bool isQuoteTweet;
  final String? quotedTweetId;
  final String? replyToTweetId;
  final String? replyToUserId;
  final List<String> hashtags;
  final List<String> mentions;
  final String? communityId;
  final bool isPinned;
  final TweetModel? originalTweet;
  final TweetModel? quotedTweet;
  final TweetModel? replyToTweet;
  final UserModel? user;
  final UserModel? retweetedByUser;
  final UserModel? replyToUser;
  final List<TweetModel> replies;

  TweetModel({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrls = const [],
    required this.createdAt,
    this.likesCount = 0,
    this.retweetsCount = 0,
    this.repliesCount = 0,
    this.quoteTweetsCount = 0,
    this.likedBy = const [],
    this.retweetedBy = const [],
    this.isRetweet = false,
    this.originalTweetId,
    this.retweetedByUserId,
    this.isQuoteTweet = false,
    this.quotedTweetId,
    this.replyToTweetId,
    this.replyToUserId,
    this.hashtags = const [],
    this.mentions = const [],
    this.communityId,
    this.isPinned = false,
    this.originalTweet,
    this.quotedTweet,
    this.replyToTweet,
    this.user,
    this.retweetedByUser,
    this.replyToUser,
    this.replies = const [],
  });

  factory TweetModel.fromJson(Map<String, dynamic> json) {
    return TweetModel(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['userId'] is String
          ? json['userId']
          : json['userId']?['_id'] ?? '', // Extract _id from populated userId
      content: json['content'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      likesCount: json['likesCount'] ?? 0,
      retweetsCount: json['retweetsCount'] ?? 0,
      repliesCount: json['repliesCount'] ?? 0,
      quoteTweetsCount: json['quoteTweetsCount'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
      retweetedBy: List<String>.from(json['retweetedBy'] ?? []),
      isRetweet: json['isRetweet'] ?? false,
      originalTweetId: json['originalTweetId'],
      retweetedByUserId: json['retweetedByUserId'] is String
          ? json['retweetedByUserId']
          : json['retweetedByUserId']?['_id'],
      isQuoteTweet: json['isQuoteTweet'] ?? false,
      quotedTweetId: json['quotedTweetId'],
      replyToTweetId: json['replyToTweetId'],
      replyToUserId: json['replyToUserId'] is String
          ? json['replyToUserId']
          : json['replyToUserId']?['_id'],
      hashtags: List<String>.from(json['hashtags'] ?? []),
      mentions: List<String>.from(json['mentions'] ?? []),
      communityId: json['communityId'],
      isPinned: json['isPinned'] ?? false,
      originalTweet: json['originalTweet'] != null
          ? TweetModel.fromJson(json['originalTweet'])
          : null,
      quotedTweet: json['quotedTweet'] != null
          ? TweetModel.fromJson(json['quotedTweet'])
          : null,
      replyToTweet: json['replyToTweet'] != null
          ? TweetModel.fromJson(json['replyToTweet'])
          : null,
      user: json['userId'] != null && json['userId'] is Map
          ? UserModel.fromJson(json['userId']) // Use populated userId as user
          : null,
      retweetedByUser:
          json['retweetedByUserId'] != null && json['retweetedByUserId'] is Map
          ? UserModel.fromJson(json['retweetedByUserId'])
          : null,
      replyToUser: json['replyToUserId'] != null && json['replyToUserId'] is Map
          ? UserModel.fromJson(json['replyToUserId'])
          : null,
      replies: json['replies'] != null
          ? (json['replies'] as List)
                .map((reply) => TweetModel.fromJson(reply))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'imageUrls': imageUrls,
      'createdAt': createdAt.toIso8601String(),
      'likesCount': likesCount,
      'retweetsCount': retweetsCount,
      'repliesCount': repliesCount,
      'quoteTweetsCount': quoteTweetsCount,
      'likedBy': likedBy,
      'retweetedBy': retweetedBy,
      'isRetweet': isRetweet,
      'originalTweetId': originalTweetId,
      'retweetedByUserId': retweetedByUserId,
      'isQuoteTweet': isQuoteTweet,
      'quotedTweetId': quotedTweetId,
      'replyToTweetId': replyToTweetId,
      'replyToUserId': replyToUserId,
      'hashtags': hashtags,
      'mentions': mentions,
      'communityId': communityId,
      'isPinned': isPinned,
      'originalTweet': originalTweet?.toJson(),
      'quotedTweet': quotedTweet?.toJson(),
      'replyToTweet': replyToTweet?.toJson(),
      'user': user?.toJson(),
      'retweetedByUser': retweetedByUser?.toJson(),
      'replyToUser': replyToUser?.toJson(),
      'replies': replies.map((reply) => reply.toJson()).toList(),
    };
  }

  TweetModel copyWith({
    String? id,
    String? userId,
    String? content,
    List<String>? imageUrls,
    DateTime? createdAt,
    int? likesCount,
    int? retweetsCount,
    int? repliesCount,
    int? quoteTweetsCount,
    List<String>? likedBy,
    List<String>? retweetedBy,
    bool? isRetweet,
    String? originalTweetId,
    String? retweetedByUserId,
    bool? isQuoteTweet,
    String? quotedTweetId,
    String? replyToTweetId,
    String? replyToUserId,
    List<String>? hashtags,
    List<String>? mentions,
    String? communityId,
    bool? isPinned,
    TweetModel? originalTweet,
    TweetModel? quotedTweet,
    TweetModel? replyToTweet,
    UserModel? user,
    UserModel? retweetedByUser,
    UserModel? replyToUser,
    List<TweetModel>? replies,
  }) {
    return TweetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      retweetsCount: retweetsCount ?? this.retweetsCount,
      repliesCount: repliesCount ?? this.repliesCount,
      quoteTweetsCount: quoteTweetsCount ?? this.quoteTweetsCount,
      likedBy: likedBy ?? this.likedBy,
      retweetedBy: retweetedBy ?? this.retweetedBy,
      isRetweet: isRetweet ?? this.isRetweet,
      originalTweetId: originalTweetId ?? this.originalTweetId,
      retweetedByUserId: retweetedByUserId ?? this.retweetedByUserId,
      isQuoteTweet: isQuoteTweet ?? this.isQuoteTweet,
      quotedTweetId: quotedTweetId ?? this.quotedTweetId,
      replyToTweetId: replyToTweetId ?? this.replyToTweetId,
      replyToUserId: replyToUserId ?? this.replyToUserId,
      hashtags: hashtags ?? this.hashtags,
      mentions: mentions ?? this.mentions,
      communityId: communityId ?? this.communityId,
      isPinned: isPinned ?? this.isPinned,
      originalTweet: originalTweet ?? this.originalTweet,
      quotedTweet: quotedTweet ?? this.quotedTweet,
      replyToTweet: replyToTweet ?? this.replyToTweet,
      user: user ?? this.user,
      retweetedByUser: retweetedByUser ?? this.retweetedByUser,
      replyToUser: replyToUser ?? this.replyToUser,
      replies: replies ?? this.replies,
    );
  }
}
