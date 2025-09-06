import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/app_constants.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;
  String? _authToken;

  bool get isConnected => _isConnected;

  // Event callbacks
  Function(MessageModel)? onNewMessage;
  Function(NotificationModel)? onNewNotification;
  Function(Map<String, dynamic>)? onUserTyping;
  Function(Map<String, dynamic>)? onUserStoppedTyping;
  Function(Map<String, dynamic>)? onMessageRead;
  Function(Map<String, dynamic>)? onTweetEngagementUpdate;

  void initialize(String userId, String authToken) {
    _currentUserId = userId;
    _authToken = authToken;
    _connect();
  }

  void _connect() {
    if (_socket?.connected == true) return;

    try {
      _socket = IO.io(
        AppConstants.baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setAuth({
              'token': _authToken,
            })
            .build(),
      );

      _socket!.onConnect((_) {
        print('Socket connected');
        _isConnected = true;
        _setupEventListeners();
      });

      _socket!.onDisconnect((_) {
        print('Socket disconnected');
        _isConnected = false;
      });

      _socket!.onConnectError((error) {
        print('Socket connection error: $error');
        _isConnected = false;
      });

      _socket!.onError((error) {
        print('Socket error: $error');
      });

      _socket!.connect();
    } catch (e) {
      print('Error initializing socket: $e');
    }
  }

  void _setupEventListeners() {
    // New message received
    _socket!.on('new_message', (data) {
      try {
        final message = MessageModel.fromJson(data['message']);
        onNewMessage?.call(message);
      } catch (e) {
        print('Error parsing new message: $e');
      }
    });

    // New notification received
    _socket!.on('new_notification', (data) {
      try {
        final notification = NotificationModel.fromJson(data);
        onNewNotification?.call(notification);
      } catch (e) {
        print('Error parsing new notification: $e');
      }
    });

    // User typing indicators
    _socket!.on('user_typing', (data) {
      onUserTyping?.call(data);
    });

    _socket!.on('user_stopped_typing', (data) {
      onUserStoppedTyping?.call(data);
    });

    // Message read receipts
    _socket!.on('messages_read', (data) {
      onMessageRead?.call(data);
    });

    // Real-time tweet engagement updates
    _socket!.on('tweet_engagement_update', (data) {
      onTweetEngagementUpdate?.call(data);
    });

    // User online/offline status
    _socket!.on('user_joined_conversation', (data) {
      print('User joined conversation: ${data['username']}');
    });

    _socket!.on('user_left_conversation', (data) {
      print('User left conversation: ${data['username']}');
    });

    _socket!.on('user_went_offline', (data) {
      print('User went offline: ${data['username']}');
    });
  }

  // Join a conversation room
  void joinConversation(String conversationId) {
    if (_isConnected) {
      _socket!.emit('join_conversation', {
        'conversationId': conversationId,
      });
    }
  }

  // Leave a conversation room
  void leaveConversation(String conversationId) {
    if (_isConnected) {
      _socket!.emit('leave_conversation', {
        'conversationId': conversationId,
      });
    }
  }

  // Send a message through WebSocket
  void sendMessage({
    required String conversationId,
    required String content,
    String messageType = 'text',
    List<Map<String, dynamic>>? attachments,
    String? replyToMessageId,
  }) {
    if (_isConnected) {
      _socket!.emit('send_message', {
        'conversationId': conversationId,
        'content': content,
        'messageType': messageType,
        'attachments': attachments ?? [],
        'replyToMessageId': replyToMessageId,
      });
    }
  }

  // Send typing indicator
  void startTyping(String conversationId) {
    if (_isConnected) {
      _socket!.emit('typing_start', {
        'conversationId': conversationId,
      });
    }
  }

  void stopTyping(String conversationId) {
    if (_isConnected) {
      _socket!.emit('typing_stop', {
        'conversationId': conversationId,
      });
    }
  }

  // Mark messages as read
  void markMessagesAsRead(String conversationId) {
    if (_isConnected) {
      _socket!.emit('mark_messages_read', {
        'conversationId': conversationId,
      });
    }
  }

  // Send tweet engagement update
  void sendTweetEngagement({
    required String tweetId,
    required String action, // 'like', 'retweet', 'reply'
    required bool isEngaged,
  }) {
    if (_isConnected) {
      _socket!.emit('tweet_engagement', {
        'tweetId': tweetId,
        'action': action,
        'isEngaged': isEngaged,
      });
    }
  }

  // Request notification count
  void requestNotifications() {
    if (_isConnected) {
      _socket!.emit('request_notifications');
    }
  }

  void disconnect() {
    if (_socket?.connected == true) {
      _socket!.disconnect();
    }
    _isConnected = false;
    _currentUserId = null;
    _authToken = null;
  }

  void dispose() {
    disconnect();
    _socket?.dispose();
    _socket = null;
  }
}