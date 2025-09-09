import 'dart:convert';
import 'package:http/http.dart' as http;
// import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/message_request_model.dart';
import 'api_service.dart';

class MessageService {
  final ApiService _apiService = ApiService();

  // Get conversations (accepted messages)
  Future<List<ConversationModel>> getConversations({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/v1/messages/conversations?page=$page&limit=$limit',
      );

      if (response['status'] == 'success') {
        final conversations = (response['conversations'] as List)
            .map((conv) => ConversationModel.fromJson(conv))
            .toList();
        return conversations;
      }
      return [];
    } catch (e) {
      print('Get conversations error: $e');
      return [];
    }
  }

  // Get message requests (pending connections)
  Future<List<MessageRequestModel>> getMessageRequests({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/v1/messages/connections?page=$page&limit=$limit',
      );

      if (response['status'] == 'success') {
        final requests = (response['connections'] as List)
            .map((req) => MessageRequestModel.fromJson(req))
            .toList();
        return requests;
      }
      return [];
    } catch (e) {
      print('Get message requests error: $e');
      return [];
    }
  }

  // Accept message request
  Future<bool> acceptMessageRequest(String requestId) async {
    try {
      final response = await _apiService.post(
        '/api/v1/messages/connections/$requestId/accept',
        {},
      );
      return response['status'] == 'success';
    } catch (e) {
      print('Accept message request error: $e');
      return false;
    }
  }

  // Decline message request
  Future<bool> declineMessageRequest(String requestId) async {
    try {
      final response = await _apiService.post(
        '/api/v1/messages/connections/$requestId/decline',
        {},
      );
      return response['status'] == 'success';
    } catch (e) {
      print('Decline message request error: $e');
      return false;
    }
  }

  // Get messages from conversation
  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/v1/messages/conversations/$conversationId?page=$page&limit=$limit',
      );

      if (response['status'] == 'success') {
        final messages = (response['messages'] as List)
            .map((msg) => MessageModel.fromJson(msg))
            .toList();
        return messages;
      }
      return [];
    } catch (e) {
      print('Get messages error: $e');
      return [];
    }
  }

  // Send message
  Future<Map<String, dynamic>?> sendMessage({
    required String receiverId,
    required String content,
    String messageType = 'text',
    List<String> attachments = const [],
    String? replyToMessageId,
  }) async {
    try {
      final response = await _apiService.post('/api/v1/messages', {
        'receiverId': receiverId,
        'content': content,
        'messageType': messageType,
        'attachments': attachments,
        'replyToMessageId': replyToMessageId,
      });

      return response;
    } catch (e) {
      print('Send message error: $e');
      return null;
    }
  }

  // Mark conversation as read
  Future<bool> markConversationAsRead(String conversationId) async {
    try {
      final response = await _apiService.post(
        '/api/v1/messages/conversations/$conversationId/read',
        {},
      );
      return response['status'] == 'success';
    } catch (e) {
      print('Mark as read error: $e');
      return false;
    }
  }
}
