import 'user_model.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String? conversationId;
  final String content;
  final String type; // text, image, gif
  final String? imageUrl;
  final DateTime createdAt;
  final bool isRead;
  final bool isDeleted;
  final String? replyToMessageId;
  final UserModel? sender;
  final UserModel? receiver;
  final MessageModel? replyToMessage;
  
  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.conversationId,
    required this.content,
    this.type = 'text',
    this.imageUrl,
    required this.createdAt,
    this.isRead = false,
    this.isDeleted = false,
    this.replyToMessageId,
    this.sender,
    this.receiver,
    this.replyToMessage,
  });
  
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      conversationId: json['conversationId'],
      content: json['content'] ?? '',
      type: json['type'] ?? 'text',
      imageUrl: json['imageUrl'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      replyToMessageId: json['replyToMessageId'],
      sender: json['sender'] != null 
          ? UserModel.fromJson(json['sender'])
          : null,
      receiver: json['receiver'] != null 
          ? UserModel.fromJson(json['receiver'])
          : null,
      replyToMessage: json['replyToMessage'] != null 
          ? MessageModel.fromJson(json['replyToMessage'])
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'conversationId': conversationId,
      'content': content,
      'type': type,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'isDeleted': isDeleted,
      'replyToMessageId': replyToMessageId,
      'sender': sender?.toJson(),
      'receiver': receiver?.toJson(),
      'replyToMessage': replyToMessage?.toJson(),
    };
  }
  
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? conversationId,
    String? content,
    String? type,
    String? imageUrl,
    DateTime? createdAt,
    bool? isRead,
    bool? isDeleted,
    String? replyToMessageId,
    UserModel? sender,
    UserModel? receiver,
    MessageModel? replyToMessage,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      replyToMessage: replyToMessage ?? this.replyToMessage,
    );
  }
}

class ConversationModel {
  final String id;
  final List<String> participantIds;
  final MessageModel? lastMessage;
  final DateTime updatedAt;
  final Map<String, int> unreadCounts;
  final List<UserModel> participants;
  
  ConversationModel({
    required this.id,
    required this.participantIds,
    this.lastMessage,
    required this.updatedAt,
    this.unreadCounts = const {},
    this.participants = const [],
  });
  
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] ?? '',
      participantIds: List<String>.from(json['participantIds'] ?? []),
      lastMessage: json['lastMessage'] != null 
          ? MessageModel.fromJson(json['lastMessage'])
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      unreadCounts: Map<String, int>.from(json['unreadCounts'] ?? {}),
      participants: json['participants'] != null 
          ? (json['participants'] as List)
              .map((user) => UserModel.fromJson(user))
              .toList()
          : [],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantIds': participantIds,
      'lastMessage': lastMessage?.toJson(),
      'updatedAt': updatedAt.toIso8601String(),
      'unreadCounts': unreadCounts,
      'participants': participants.map((user) => user.toJson()).toList(),
    };
  }
}