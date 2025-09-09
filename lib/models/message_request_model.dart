import 'user_model.dart';
import 'message_model.dart';

class MessageRequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String conversationId;
  final String status; // pending, accepted, declined
  final String firstMessageId;
  final DateTime createdAt;
  final DateTime? respondedAt;
  
  // Populated fields
  final UserModel? sender;
  final UserModel? receiver;
  final MessageModel? firstMessage;
  
  MessageRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.conversationId,
    required this.status,
    required this.firstMessageId,
    required this.createdAt,
    this.respondedAt,
    this.sender,
    this.receiver,
    this.firstMessage,
  });
  
  factory MessageRequestModel.fromJson(Map<String, dynamic> json) {
    return MessageRequestModel(
      id: json['_id'] ?? json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      conversationId: json['conversationId'] ?? '',
      status: json['status'] ?? 'pending',
      firstMessageId: json['firstMessageId'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      respondedAt: json['respondedAt'] != null 
          ? DateTime.parse(json['respondedAt'])
          : null,
      sender: json['senderId'] != null && json['senderId'] is Map
          ? UserModel.fromJson(json['senderId'])
          : null,
      receiver: json['receiverId'] != null && json['receiverId'] is Map
          ? UserModel.fromJson(json['receiverId'])
          : null,
      firstMessage: json['firstMessageId'] != null && json['firstMessageId'] is Map
          ? MessageModel.fromJson(json['firstMessageId'])
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'conversationId': conversationId,
      'status': status,
      'firstMessageId': firstMessageId,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'sender': sender?.toJson(),
      'receiver': receiver?.toJson(),
      'firstMessage': firstMessage?.toJson(),
    };
  }
  
  MessageRequestModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? conversationId,
    String? status,
    String? firstMessageId,
    DateTime? createdAt,
    DateTime? respondedAt,
    UserModel? sender,
    UserModel? receiver,
    MessageModel? firstMessage,
  }) {
    return MessageRequestModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      conversationId: conversationId ?? this.conversationId,
      status: status ?? this.status,
      firstMessageId: firstMessageId ?? this.firstMessageId,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      firstMessage: firstMessage ?? this.firstMessage,
    );
  }
}