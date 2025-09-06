import 'package:flutter/foundation.dart';
import 'message_model.dart';
import 'user_model.dart';

class ConversationModel {
  final String id;
  final List<String> participantIds;
  final List<UserModel> participants;
  final MessageModel? lastMessage;
  final DateTime lastActivity;
  final Map<String, int> unreadCounts;

  ConversationModel({
    required this.id,
    required this.participantIds,
    required this.participants,
    this.lastMessage,
    required this.lastActivity,
    required this.unreadCounts,
  });
}
