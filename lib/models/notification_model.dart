import 'user_model.dart';
import 'tweet_model.dart';

class NotificationModel {
  final String id;
  final String userId; // User who receives the notification
  final String type; // like, retweet, follow, reply, mention, etc.
  final String? fromUserId; // User who triggered the notification
  final String? tweetId; // Related tweet ID if applicable
  final String? message;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? metadata;
  final UserModel? fromUser;
  final TweetModel? tweet;
  
  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    this.fromUserId,
    this.tweetId,
    this.message,
    required this.createdAt,
    this.isRead = false,
    this.metadata,
    this.fromUser,
    this.tweet,
  });
  
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      fromUserId: json['fromUserId'],
      tweetId: json['tweetId'],
      message: json['message'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      metadata: json['metadata'],
      fromUser: json['fromUser'] != null 
          ? UserModel.fromJson(json['fromUser'])
          : null,
      tweet: json['tweet'] != null 
          ? TweetModel.fromJson(json['tweet'])
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'fromUserId': fromUserId,
      'tweetId': tweetId,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'metadata': metadata,
      'fromUser': fromUser?.toJson(),
      'tweet': tweet?.toJson(),
    };
  }
  
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? fromUserId,
    String? tweetId,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? metadata,
    UserModel? fromUser,
    TweetModel? tweet,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      fromUserId: fromUserId ?? this.fromUserId,
      tweetId: tweetId ?? this.tweetId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
      fromUser: fromUser ?? this.fromUser,
      tweet: tweet ?? this.tweet,
    );
  }
  
  String get displayMessage {
    switch (type) {
      case 'like':
        return '${fromUser?.displayName ?? 'Someone'} liked your tweet';
      case 'retweet':
        return '${fromUser?.displayName ?? 'Someone'} retweeted your tweet';
      case 'follow':
        return '${fromUser?.displayName ?? 'Someone'} followed you';
      case 'reply':
        return '${fromUser?.displayName ?? 'Someone'} replied to your tweet';
      case 'mention':
        return '${fromUser?.displayName ?? 'Someone'} mentioned you in a tweet';
      case 'quote':
        return '${fromUser?.displayName ?? 'Someone'} quoted your tweet';
      default:
        return message ?? 'New notification';
    }
  }
}