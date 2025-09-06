import 'user_model.dart';

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final DateTime createdAt;
  final bool isRead;
  final String messageType; // text, image, video, audio, file
  final UserModel? sender;
  final String? replyToMessageId;
  final MessageModel? replyToMessage;
  
  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.imageUrls = const [],
    this.videoUrls = const [],
    required this.createdAt,
    this.isRead = false,
    this.messageType = 'text',
    this.sender,
    this.replyToMessageId,
    this.replyToMessage,
  });
  
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? '',
      content: json['content'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      videoUrls: List<String>.from(json['videoUrls'] ?? []),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      messageType: json['messageType'] ?? 'text',
      sender: json['sender'] != null 
          ? UserModel.fromJson(json['sender'])
          : null,
      replyToMessageId: json['replyToMessageId'],
      replyToMessage: json['replyToMessage'] != null 
          ? MessageModel.fromJson(json['replyToMessage'])
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'messageType': messageType,
      'sender': sender?.toJson(),
      'replyToMessageId': replyToMessageId,
      'replyToMessage': replyToMessage?.toJson(),
    };
  }
  
  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    List<String>? imageUrls,
    List<String>? videoUrls,
    DateTime? createdAt,
    bool? isRead,
    String? messageType,
    UserModel? sender,
    String? replyToMessageId,
    MessageModel? replyToMessage,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      messageType: messageType ?? this.messageType,
      sender: sender ?? this.sender,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
    );
  }
}

class ConversationModel {
  final String id;
  final List<String> participants;
  final String? lastMessageId;
  final MessageModel? lastMessage;
  final DateTime lastActivity;
  final List<UserModel> participantUsers;
  final int unreadCount;
  final bool isGroup;
  final String? groupName;
  final String? groupImageUrl;
  
  ConversationModel({
    required this.id,
    required this.participants,
    this.lastMessageId,
    this.lastMessage,
    required this.lastActivity,
    this.participantUsers = const [],
    this.unreadCount = 0,
    this.isGroup = false,
    this.groupName,
    this.groupImageUrl,
  });
  
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      lastMessageId: json['lastMessageId'],
      lastMessage: json['lastMessage'] != null 
          ? MessageModel.fromJson(json['lastMessage'])
          : null,
      lastActivity: json['lastActivity'] != null 
          ? DateTime.parse(json['lastActivity'])
          : DateTime.now(),
      participantUsers: json['participantUsers'] != null 
          ? (json['participantUsers'] as List)
              .map((user) => UserModel.fromJson(user))
              .toList()
          : [],
      unreadCount: json['unreadCount'] ?? 0,
      isGroup: json['isGroup'] ?? false,
      groupName: json['groupName'],
      groupImageUrl: json['groupImageUrl'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'lastMessageId': lastMessageId,
      'lastMessage': lastMessage?.toJson(),
      'lastActivity': lastActivity.toIso8601String(),
      'participantUsers': participantUsers.map((user) => user.toJson()).toList(),
      'unreadCount': unreadCount,
      'isGroup': isGroup,
      'groupName': groupName,
      'groupImageUrl': groupImageUrl,
    };
  }
}