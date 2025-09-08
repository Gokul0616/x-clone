// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../constants/app_constants.dart';
// import '../models/user_model.dart';
// import '../models/tweet_model.dart';
// import '../models/community_model.dart';
// import '../models/message_model.dart';
// import '../models/notification_model.dart';
// import 'mock_api_service.dart';

// class ApiService {
//   static final ApiService _instance = ApiService._internal();
//   factory ApiService() => _instance;
//   ApiService._internal();

//   final String baseUrl = AppConstants.baseUrl;
//   final MockApiService _mockService = MockApiService();

//   // Helper method to get headers
//   Map<String, String> get _headers => {
//     'Content-Type': 'application/json',
//     'Accept': 'application/json',

//   };

//   Map<String, String> _headersWithAuth(String token) => {
//     ..._headers,
//     'Authorization': 'Bearer $token',
//   };

//   // Authentication
//   Future<UserModel?> login(String email, String password) async {
//     if (AppConstants.useMockApi) {
//       return await _mockService.login(email, password);
//     }

//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl${AppConstants.apiVersion}${AppConstants.loginEndpoint}'),
//         headers: _headers,
//         body: json.encode({
//           'email': email,
//           'password': password,
//         }),
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return UserModel.fromJson(data['user']);
//       }
//       return null;
//     } catch (e) {
//       print('Login error: $e');
//       return null;
//     }
//   }

//   Future<UserModel?> register(String email, String password, String username, String displayName) async {
//     if (AppConstants.useMockApi) {
//       return await _mockService.register(email, password, username, displayName);
//     }

//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl${AppConstants.apiVersion}${AppConstants.registerEndpoint}'),
//         headers: _headers,
//         body: json.encode({
//           'email': email,
//           'password': password,
//           'username': username,
//           'displayName': displayName,
//         }),
//       );

//       if (response.statusCode == 201) {
//         final data = json.decode(response.body);
//         return UserModel.fromJson(data['user']);
//       }
//       return null;
//     } catch (e) {
//       print('Register error: $e');
//       return null;
//     }
//   }

//   // Tweets
//   Future<List<TweetModel>> getTimeline({int page = 1, int limit = 20}) async {
//     if (AppConstants.useMockApi) {
//       return await _mockService.getTimeline(page: page, limit: limit);
//     }

//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl${AppConstants.apiVersion}${AppConstants.tweetsEndpoint}/timeline?page=$page&limit=$limit'),
//         headers: _headers,
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return (data['tweets'] as List)
//             .map((tweet) => TweetModel.fromJson(tweet))
//             .toList();
//       }
//       return [];
//     } catch (e) {
//       print('Get timeline error: $e');
//       return [];
//     }
//   }

//   Future<TweetModel?> createTweet(String content, {List<String>? imageUrls, String? replyToTweetId, String? quotedTweetId}) async {
//     if (AppConstants.useMockApi) {
//       return await _mockService.createTweet(content, imageUrls: imageUrls, replyToTweetId: replyToTweetId, quotedTweetId: quotedTweetId);
//     }

//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl${AppConstants.apiVersion}${AppConstants.tweetsEndpoint}'),
//         headers: _headers,
//         body: json.encode({
//           'content': content,
//           'imageUrls': imageUrls,
//           'replyToTweetId': replyToTweetId,
//           'quotedTweetId': quotedTweetId,
//         }),
//       );

//       if (response.statusCode == 201) {
//         final data = json.decode(response.body);
//         return TweetModel.fromJson(data['tweet']);
//       }
//       return null;
//     } catch (e) {
//       print('Create tweet error: $e');
//       return null;
//     }
//   }

//   Future<bool> likeTweet(String tweetId) async {
//     if (AppConstants.useMockApi) {
//       return await _mockService.likeTweet(tweetId);
//     }

//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl${AppConstants.apiVersion}${AppConstants.tweetsEndpoint}/$tweetId/like'),
//         headers: _headers,
//       );

//       return response.statusCode == 200;
//     } catch (e) {
//       print('Like tweet error: $e');
//       return false;
//     }
//   }

//   Future<bool> retweetTweet(String tweetId) async {
//     if (AppConstants.useMockApi) {
//       return await _mockService.retweetTweet(tweetId);
//     }

//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl${AppConstants.apiVersion}${AppConstants.tweetsEndpoint}/$tweetId/retweet'),
//         headers: _headers,
//       );

//       return response.statusCode == 200;
//     } catch (e) {
//       print('Retweet error: $e');
//       return false;
//     }
//   }

//   Future<List<TweetModel>> getTweetReplies(String tweetId) async {
//     if (AppConstants.useMockApi) {
//       return await _mockService.getTweetReplies(tweetId);
//     }

//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl${AppConstants.apiVersion}${AppConstants.tweetsEndpoint}/$tweetId/replies'),
//         headers: _headers,
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return (data['replies'] as List)
//             .map((tweet) => TweetModel.fromJson(tweet))
//             .toList();
//       }
//       return [];
//     } catch (e) {
//       print('Get replies error: $e');
//       return [];
//     }
//   }

//   // Users
//   Future<UserModel?> getUserById(String userId) async {
//     if (AppConstants.useMockApi) {
//       return await _mockService.getUserById(userId);
//     }

//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl${AppConstants.apiVersion}${AppConstants.usersEndpoint}/$userId'),
//         headers: _headers,
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return UserModel.fromJson(data['user']);
//       }
//       return null;
//     } catch (e) {
//       print('Get user error: $e');
//       return null;
//     }
//   }

//   Future<List<UserModel>> searchUsers(String query) async {
//     if (AppConstants.useMockApi) {
//       return await _mockService.searchUsers(query);
//     }

//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl${AppConstants.apiVersion}${AppConstants.searchEndpoint}/users?q=$query'),
//         headers: _headers,
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return (data['users'] as List)
//             .map((user) => UserModel.fromJson(user))
//             .toList();
//       }
//       return [];
//     } catch (e) {
//       print('Search users error: $e');
//       return [];
//     }
//   }

//   Future<bool> followUser(String userId) async {
//     if (AppConstants.useMockApi) {
//       return await _mockService.followUser(userId);
//     }

//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl${AppConstants.apiVersion}${AppConstants.usersEndpoint}/$userId/follow'),
//         headers: _headers,
//       );

//       return response.statusCode == 200;
//     } catch (e) {
//       print('Follow user error: $e');
//       return false;
//     }
//   }

//   // Communities
//   Future<List<CommunityModel>> getCommunities() async {
//     if (AppConstants.useMockApi) {
//       return await _mockService.getCommunities();
//     }

//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl${AppConstants.apiVersion}${AppConstants.communitiesEndpoint}'),
//         headers: _headers,
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return (data['communities'] as List)
//             .map((community) => CommunityModel.fromJson(community))
//             .toList();
//       }
//       return [];
//     } catch (e) {
//       print('Get communities error: $e');
//       return [];
//     }
//   }

//   Future<CommunityModel?> createCommunity(String name, String description) async {
//     if (AppConstants.useMockApi) {
//       return await _mockService.createCommunity(name, description);
//     }

//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl${AppConstants.apiVersion}${AppConstants.communitiesEndpoint}'),
//         headers: _headers,
//         body: json.encode({
//           'name': name,
//           'description': description,
//         }),
//       );

//       if (response.statusCode == 201) {
//         final data = json.decode(response.body);
//         return CommunityModel.fromJson(data['community']);
//       }
//       return null;
//     } catch (e) {
//       print('Create community error: $e');
//       return null;
//     }
//   }

//   // Messages
//   Future<List<ConversationModel>> getConversations() async {
//     if (AppConstants.useMockApi) {
//       return await _mockService.getConversations();
//     }

//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl${AppConstants.apiVersion}${AppConstants.messagesEndpoint}/conversations'),
//         headers: _headers,
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return (data['conversations'] as List)
//             .map((conversation) => ConversationModel.fromJson(conversation))
//             .toList();
//       }
//       return [];
//     } catch (e) {
//       print('Get conversations error: $e');
//       return [];
//     }
//   }

//   Future<List<MessageModel>> getMessages(String conversationId) async {
//     if (AppConstants.useMockApi) {
//       return await _mockService.getMessages(conversationId);
//     }

//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl${AppConstants.apiVersion}${AppConstants.messagesEndpoint}/conversations/$conversationId'),
//         headers: _headers,
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return (data['messages'] as List)
//             .map((message) => MessageModel.fromJson(message))
//             .toList();
//       }
//       return [];
//     } catch (e) {
//       print('Get messages error: $e');
//       return [];
//     }
//   }

//   Future<MessageModel?> sendMessage(String receiverId, String content) async {
//     if (AppConstants.useMockApi) {
//       return await _mockService.sendMessage(receiverId, content);
//     }

//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl${AppConstants.apiVersion}${AppConstants.messagesEndpoint}'),
//         headers: _headers,
//         body: json.encode({
//           'receiverId': receiverId,
//           'content': content,
//         }),
//       );

//       if (response.statusCode == 201) {
//         final data = json.decode(response.body);
//         return MessageModel.fromJson(data['message']);
//       }
//       return null;
//     } catch (e) {
//       print('Send message error: $e');
//       return null;
//     }
//   }

//   // Notifications
//   Future<List<NotificationModel>> getNotifications() async {
//     if (AppConstants.useMockApi) {
//       return await _mockService.getNotifications();
//     }

//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl${AppConstants.apiVersion}${AppConstants.notificationsEndpoint}'),
//         headers: _headers,
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return (data['notifications'] as List)
//             .map((notification) => NotificationModel.fromJson(notification))
//             .toList();
//       }
//       return [];
//     } catch (e) {
//       print('Get notifications error: $e');
//       return [];
//     }
//   }
// }

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/tweet_model.dart';
import '../models/community_model.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import 'mock_api_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String baseUrl = AppConstants.baseUrl;
  final MockApiService _mockService = MockApiService();
  String? _token; // Store token in memory

  // Helper method to get headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Map<String, String> _headersWithAuth() => {
    ..._headers,
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Store token using SharedPreferences
  Future<void> _storeToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Retrieve token using SharedPreferences
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  // Clear token using SharedPreferences
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Authentication
  Future<UserModel?> login(String email, String password) async {
    if (AppConstants.useMockApi) {
      return await _mockService.login(email, password);
    }

    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl${AppConstants.apiVersion}${AppConstants.loginEndpoint}',
        ),
        headers: _headers, // No auth token for login
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        if (token != null) {
          await _storeToken(token); // Store token
        }
        return UserModel.fromJson(data['user']);
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<UserModel?> register(
    String email,
    String password,
    String username,
    String displayName,
  ) async {
    if (AppConstants.useMockApi) {
      return await _mockService.register(
        email,
        password,
        username,
        displayName,
      );
    }

    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl${AppConstants.apiVersion}${AppConstants.registerEndpoint}',
        ),
        headers: _headers, // No auth token for register
        body: json.encode({
          'email': email,
          'password': password,
          'username': username,
          'displayName': displayName,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final token = data['token'];
        if (token != null) {
          await _storeToken(token); // Store token
        }
        return UserModel.fromJson(data['user']);
      }
      return null;
    } catch (e) {
      print('Register error: $e');
      return null;
    }
  }

  // Tweets
  Future<List<TweetModel>> getTimeline({int page = 1, int limit = 20}) async {
    if (AppConstants.useMockApi) {
      return await _mockService.getTimeline(page: page, limit: limit);
    }

    try {
      await _loadToken(); // Load token before API call
      final response = await http.get(
        Uri.parse(
          '$baseUrl${AppConstants.apiVersion}${AppConstants.tweetsEndpoint}/timeline?page=$page&limit=$limit',
        ),
        headers: _headersWithAuth(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['tweets'] as List)
            .map((tweet) => TweetModel.fromJson(tweet))
            .toList();
      }
      return [];
    } catch (e) {
      print('Get timeline error: $e');
      return [];
    }
  }

  Future<TweetModel?> createTweet(
    String content, {
    List<String>? imageUrls,
    String? replyToTweetId,
    String? quotedTweetId,
  }) async {
    if (AppConstants.useMockApi) {
      return await _mockService.createTweet(
        content,
        imageUrls: imageUrls,
        replyToTweetId: replyToTweetId,
        quotedTweetId: quotedTweetId,
      );
    }

    try {
      await _loadToken(); // Load token before API call
      final response = await http.post(
        Uri.parse(
          '$baseUrl${AppConstants.apiVersion}${AppConstants.tweetsEndpoint}',
        ),
        headers: _headersWithAuth(),
        body: json.encode({
          'content': content,
          'imageUrls': imageUrls,
          'replyToTweetId': replyToTweetId,
          'quotedTweetId': quotedTweetId,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return TweetModel.fromJson(data['tweet']);
      }
      return null;
    } catch (e) {
      print('Create tweet error: $e');
      return null;
    }
  }

  Future<bool> likeTweet(String tweetId) async {
    if (AppConstants.useMockApi) {
      return await _mockService.likeTweet(tweetId);
    }

    try {
      await _loadToken(); // Load token before API call
      final response = await http.post(
        Uri.parse(
          '$baseUrl${AppConstants.apiVersion}${AppConstants.tweetsEndpoint}/$tweetId/like',
        ),
        headers: _headersWithAuth(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Like tweet error: $e');
      return false;
    }
  }

  Future<bool> retweetTweet(String tweetId) async {
    if (AppConstants.useMockApi) {
      return await _mockService.retweetTweet(tweetId);
    }

    try {
      await _loadToken(); // Load token before API call
      final response = await http.post(
        Uri.parse(
          '$baseUrl${AppConstants.apiVersion}${AppConstants.tweetsEndpoint}/$tweetId/retweet',
        ),
        headers: _headersWithAuth(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Retweet error: $e');
      return false;
    }
  }

  Future<List<TweetModel>> getTweetReplies(String tweetId) async {
    if (AppConstants.useMockApi) {
      return await _mockService.getTweetReplies(tweetId);
    }

    try {
      await _loadToken(); // Load token before API call
      final response = await http.get(
        Uri.parse(
          '$baseUrl${AppConstants.apiVersion}${AppConstants.tweetsEndpoint}/$tweetId/replies',
        ),
        headers: _headersWithAuth(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['replies'] as List)
            .map((tweet) => TweetModel.fromJson(tweet))
            .toList();
      }
      return [];
    } catch (e) {
      print('Get replies error: $e');
      return [];
    }
  }

  // Users
  Future<UserModel?> getUserById(String userId) async {
    if (AppConstants.useMockApi) {
      return await _mockService.getUserById(userId);
    }

    try {
      await _loadToken(); // Load token before API call
      final response = await http.get(
        Uri.parse(
          '$baseUrl${AppConstants.apiVersion}${AppConstants.usersEndpoint}/$userId',
        ),
        headers: _headersWithAuth(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserModel.fromJson(data['user']);
      }
      return null;
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    if (AppConstants.useMockApi) {
      return await _mockService.searchUsers(query);
    }

    try {
      await _loadToken(); // Load token before API call
      final response = await http.get(
        Uri.parse(
          '$baseUrl${AppConstants.apiVersion}${AppConstants.searchEndpoint}/users?q=$query',
        ),
        headers: _headersWithAuth(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['users'] as List)
            .map((user) => UserModel.fromJson(user))
            .toList();
      }
      return [];
    } catch (e) {
      print('Search users error: $e');
      return [];
    }
  }

  Future<bool> followUser(String userId) async {
    if (AppConstants.useMockApi) {
      return await _mockService.followUser(userId);
    }

    try {
      await _loadToken(); // Load token before API call
      final response = await http.post(
        Uri.parse(
          '$baseUrl${AppConstants.apiVersion}${AppConstants.usersEndpoint}/$userId/follow',
        ),
        headers: _headersWithAuth(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Follow user error: $e');
      return false;
    }
  }

  // Communities
  Future<List<CommunityModel>> getCommunities() async {
    if (AppConstants.useMockApi) {
      return await _mockService.getCommunities();
    }

    try {
      await _loadToken(); // Load token before API call
      final response = await http.get(
        Uri.parse(
          '$baseUrl${AppConstants.apiVersion}${AppConstants.communitiesEndpoint}',
        ),
        headers: _headersWithAuth(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['communities'] as List)
            .map((community) => CommunityModel.fromJson(community))
            .toList();
      }
      return [];
    } catch (e) {
      print('Get communities error: $e');
      return [];
    }
  }

  Future<CommunityModel?> createCommunity(
    String name,
    String description,
  ) async {
    if (AppConstants.useMockApi) {
      return await _mockService.createCommunity(name, description);
    }

    try {
      await _loadToken(); // Load token before API call
      final response = await http.post(
        Uri.parse(
          '$baseUrl${AppConstants.apiVersion}${AppConstants.communitiesEndpoint}',
        ),
        headers: _headersWithAuth(),
        body: json.encode({'name': name, 'description': description}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return CommunityModel.fromJson(data['community']);
      }
      return null;
    } catch (e) {
      print('Create community error: $e');
      return null;
    }
  }

  // Messages
  Future<List<ConversationModel>> getConversations() async {
    if (AppConstants.useMockApi) {
      return await _mockService.getConversations();
    }

    try {
      await _loadToken(); // Load token before API call
      final response = await http.get(
        Uri.parse(
          '$baseUrl${AppConstants.apiVersion}${AppConstants.messagesEndpoint}/conversations',
        ),
        headers: _headersWithAuth(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['conversations'] as List)
            .map((conversation) => ConversationModel.fromJson(conversation))
            .toList();
      }
      return [];
    } catch (e) {
      print('Get conversations error: $e');
      return [];
    }
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    if (AppConstants.useMockApi) {
      return await _mockService.getMessages(conversationId);
    }

    try {
      await _loadToken(); // Load token before API call
      final response = await http.get(
        Uri.parse(
          '$baseUrl${AppConstants.apiVersion}${AppConstants.messagesEndpoint}/conversations/$conversationId',
        ),
        headers: _headersWithAuth(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['messages'] as List)
            .map((message) => MessageModel.fromJson(message))
            .toList();
      }
      return [];
    } catch (e) {
      print('Get messages error: $e');
      return [];
    }
  }

  Future<MessageModel?> sendMessage(String receiverId, String content) async {
    if (AppConstants.useMockApi) {
      return await _mockService.sendMessage(receiverId, content);
    }

    try {
      await _loadToken(); // Load token before API call
      final response = await http.post(
        Uri.parse(
          '$baseUrl${AppConstants.apiVersion}${AppConstants.messagesEndpoint}',
        ),
        headers: _headersWithAuth(),
        body: json.encode({'receiverId': receiverId, 'content': content}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return MessageModel.fromJson(data['message']);
      }
      return null;
    } catch (e) {
      print('Send message error: $e');
      return null;
    }
  }

  // Notifications
  Future<List<NotificationModel>> getNotifications() async {
    if (AppConstants.useMockApi) {
      return await _mockService.getNotifications();
    }

    try {
      await _loadToken(); // Load token before API call
      final response = await http.get(
        Uri.parse(
          '$baseUrl${AppConstants.apiVersion}${AppConstants.notificationsEndpoint}',
        ),
        headers: _headersWithAuth(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['notifications'] as List)
            .map((notification) => NotificationModel.fromJson(notification))
            .toList();
      }
      return [];
    } catch (e) {
      print('Get notifications error: $e');
      return [];
    }
  }

  // Generic HTTP methods for story service to use
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      await _loadToken();
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headersWithAuth(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      await _loadToken();
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headersWithAuth(),
        body: json.encode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      await _loadToken();
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headersWithAuth(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return json.decode(response.body);
      } catch (e) {
        return {'status': 'success', 'data': null};
      }
    } else {
      try {
        final data = json.decode(response.body);
        throw Exception(
          data['message'] ??
              'Request failed with status ${response.statusCode}',
        );
      } catch (e) {
        throw Exception('Request failed with status ${response.statusCode}');
      }
    }
  }

  Future<Map<String, String>> getHeaders() async {
    await _loadToken();
    return _headersWithAuth();
  }
}
