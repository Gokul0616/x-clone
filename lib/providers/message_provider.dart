import 'package:flutter/foundation.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/message_request_model.dart';
import '../services/message_service.dart';

class MessageProvider with ChangeNotifier {
  final MessageService _messageService = MessageService();
  
  List<ConversationModel> _conversations = [];
  List<MessageRequestModel> _messageRequests = [];
  List<MessageModel> _currentMessages = [];
  
  bool _isLoading = false;
  bool _isLoadingRequests = false;
  bool _isLoadingMessages = false;
  String? _error;
  
  // Getters
  List<ConversationModel> get conversations => _conversations;
  List<MessageRequestModel> get messageRequests => _messageRequests;
  List<MessageModel> get currentMessages => _currentMessages;
  bool get isLoading => _isLoading;
  bool get isLoadingRequests => _isLoadingRequests;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get error => _error;
  
  int get totalRequestsCount => _messageRequests.length;
  
  // Load conversations
  Future<void> loadConversations({bool refresh = false}) async {
    if (refresh) {
      _conversations.clear();
    }
    
    _setLoading(true);
    _clearError();
    
    try {
      final conversations = await _messageService.getConversations();
      _conversations = conversations;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load conversations: ${e.toString()}');
      _setLoading(false);
    }
  }
  
  // Load message requests
  Future<void> loadMessageRequests({bool refresh = false}) async {
    if (refresh) {
      _messageRequests.clear();
    }
    
    _setLoadingRequests(true);
    _clearError();
    
    try {
      final requests = await _messageService.getMessageRequests();
      _messageRequests = requests;
      _setLoadingRequests(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load connection requests: ${e.toString()}');
      _setLoadingRequests(false);
    }
  }
  
  // Accept message request
  Future<bool> acceptMessageRequest(String requestId) async {
    try {
      final success = await _messageService.acceptMessageRequest(requestId);
      if (success) {
        // Remove from requests list
        _messageRequests.removeWhere((req) => req.id == requestId);
        notifyListeners();
        
        // Reload conversations to show the new accepted conversation
        await loadConversations(refresh: true);
      }
      return success;
    } catch (e) {
      _setError('Failed to accept connection request: ${e.toString()}');
      return false;
    }
  }
  
  // Decline message request
  Future<bool> declineMessageRequest(String requestId) async {
    try {
      final success = await _messageService.declineMessageRequest(requestId);
      if (success) {
        // Remove from requests list
        _messageRequests.removeWhere((req) => req.id == requestId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Failed to decline connection request: ${e.toString()}');
      return false;
    }
  }
  
  // Load messages for a conversation
  Future<void> loadMessages(String conversationId, {bool refresh = false}) async {
    if (refresh) {
      _currentMessages.clear();
    }
    
    _setLoadingMessages(true);
    _clearError();
    
    try {
      final messages = await _messageService.getMessages(conversationId);
      _currentMessages = messages;
      _setLoadingMessages(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load messages: ${e.toString()}');
      _setLoadingMessages(false);
    }
  }
  
  // Send message
  Future<bool> sendMessage({
    required String receiverId,
    required String content,
    String messageType = 'text',
    List<String> attachments = const [],
    String? replyToMessageId,
  }) async {
    try {
      final response = await _messageService.sendMessage(
        receiverId: receiverId,
        content: content,
        messageType: messageType,
        attachments: attachments,
        replyToMessageId: replyToMessageId,
      );
      
      if (response != null && response['status'] == 'success') {
        // Add message to current messages if viewing the conversation
        if (response['data'] != null) {
          final newMessage = MessageModel.fromJson(response['data']);
          _currentMessages.add(newMessage);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to send message: ${e.toString()}');
      return false;
    }
  }
  
  // Mark conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    await _messageService.markConversationAsRead(conversationId);
  }
  
  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setLoadingRequests(bool loading) {
    _isLoadingRequests = loading;
    notifyListeners();
  }
  
  void _setLoadingMessages(bool loading) {
    _isLoadingMessages = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
  }
  
  // Clear error manually
  void clearError() {
    _clearError();
    notifyListeners();
  }
  
  // Clear all data (for account switching)
  void clearCache() {
    _conversations.clear();
    _messageRequests.clear();
    _currentMessages.clear();
    _clearError();
    notifyListeners();
  }
  
  // Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadConversations(refresh: true),
      loadMessageRequests(refresh: true),
    ]);
  }
}