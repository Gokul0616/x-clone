import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/community_model.dart';
import '../models/message_model.dart' as messages;
import '../models/notification_model.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class UserProvider with ChangeNotifier {
  final List<UserModel> _users = [];
  List<CommunityModel> _communities = [];
  List<messages.ConversationModel> _conversations = [];
  List<NotificationModel> _notifications = [];

  bool _isLoading = false;
  String? _error;

  List<UserModel> get users => _users;
  List<CommunityModel> get communities => _communities;
  List<messages.ConversationModel> get conversations => _conversations;
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _apiService = ApiService();

  // Users
  Future<UserModel?> getUserById(String userId) async {
    try {
      // Check if user already exists in local cache
      final existingUser = _users
          .where((user) => user.id == userId)
          .firstOrNull;
      print(existingUser ?? 'User not found from user provider1');
      if (existingUser != null) {
        return existingUser;
      }

      // Fetch from API
      final user = await _apiService.getUserById(userId);
      print(user ?? 'User not found from user provider2');
      if (user != null) {
        _users.add(user);
        notifyListeners();
      }
      return user;
    } catch (e) {
      _setError('Failed to load user: ${e.toString()}');
      return null;
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    _setLoading(true);
    _clearError();

    try {
      final users = await _apiService.searchUsers(query);
      _setLoading(false);
      return users;
    } catch (e) {
      _setError('Failed to search users: ${e.toString()}');
      _setLoading(false);
      return [];
    }
  }

  Future<bool> followUser(String userId, BuildContext context) async {
    try {
      final success = await _apiService.followUser(userId);

      if (success) {
        // Update local user data if exists
        final userIndex = _users.indexWhere((user) => user.id == userId);
        if (userIndex != -1) {
          final user = _users[userIndex];
          final currentUser = context.read<AuthProvider>().currentUser;
          if (currentUser == null) return false;

          final followers = List<String>.from(user.followers);
          if (followers.contains(currentUser.id)) {
            followers.remove(currentUser.id);
          } else {
            followers.add(currentUser.id);
          }

          _users[userIndex] = user.copyWith(
            followers: followers,
            followersCount: followers.length,
          );

          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      _setError('Failed to follow user: ${e.toString()}');
      return false;
    }
  }

  // Communities
  Future<void> loadCommunities() async {
    _setLoading(true);
    _clearError();

    try {
      _communities = await _apiService.getCommunities();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load communities: ${e.toString()}');
      _setLoading(false);
    }
  }

  Future<bool> createCommunity(String name, String description) async {
    _clearError();

    try {
      final community = await _apiService.createCommunity(name, description);

      if (community != null) {
        _communities.insert(0, community);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to create community: ${e.toString()}');
      return false;
    }
  }

  Future<bool> joinCommunity(String communityId, BuildContext context) async {
    try {
      final currentUser = context.read<AuthProvider>().currentUser;
      if (currentUser == null) return false;

      final success = await _apiService.joinCommunity(communityId);

      if (success) {
        final communityIndex = _communities.indexWhere(
          (c) => c.id == communityId,
        );
        if (communityIndex != -1) {
          final community = _communities[communityIndex];
          final members = List<String>.from(community.members);

          if (members.contains(currentUser.id)) {
            members.remove(currentUser.id);
          } else {
            members.add(currentUser.id);
          }

          _communities[communityIndex] = community.copyWith(
            members: members,
            membersCount: members.length,
          );

          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      _setError('Failed to join community: ${e.toString()}');
      return false;
    }
  }

  List<CommunityModel> searchCommunities(String query) {
    return _communities
        .where(
          (community) =>
              community.name.toLowerCase().contains(query.toLowerCase()) ||
              community.description.toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              community.tags.any(
                (tag) => tag.toLowerCase().contains(query.toLowerCase()),
              ),
        )
        .toList();
  }

  // Messages
  Future<void> loadConversations() async {
    _setLoading(true);
    _clearError();

    try {
      _conversations = await _apiService.getConversations();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load conversations: ${e.toString()}');
      _setLoading(false);
    }
  }

  Future<List<messages.MessageModel>> getMessagesForConversation(
    String conversationId,
  ) async {
    try {
      return await _apiService.getMessages(conversationId);
    } catch (e) {
      _setError('Failed to load messages: ${e.toString()}');
      return [];
    }
  }

  Future<bool> sendMessage(String receiverId, String content) async {
    _clearError();

    try {
      final message = await _apiService.sendMessage(receiverId, content);

      if (message != null) {
        // Update conversation list if needed
        // In a real app, you might need to update the conversation's last message
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to send message: ${e.toString()}');
      return false;
    }
  }

  // Notifications
  Future<void> loadNotifications() async {
    _setLoading(true);
    _clearError();

    try {
      _notifications = await _apiService.getNotifications();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load notifications: ${e.toString()}');
      _setLoading(false);
    }
  }

  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      // In a real app, this would make an API call
      final notificationIndex = _notifications.indexWhere(
        (n) => n.id == notificationId,
      );
      if (notificationIndex != -1) {
        _notifications[notificationIndex] = _notifications[notificationIndex]
            .copyWith(isRead: true);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to mark notification as read: ${e.toString()}');
      return false;
    }
  }

  Future<bool> markAllNotificationsAsRead() async {
    try {
      // In a real app, this would make an API call
      _notifications = _notifications
          .map((notification) => notification.copyWith(isRead: true))
          .toList();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to mark all notifications as read: ${e.toString()}');
      return false;
    }
  }

  // Get unread notifications count
  int get unreadNotificationsCount {
    return _notifications.where((notification) => !notification.isRead).length;
  }

  // Get unread messages count
  int get unreadMessagesCount {
    var count = 0;

    for (final conversation in _conversations) {
      count += conversation.unreadCount.toInt();
    }

    return count;
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
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

  // Clear cache for account switching
  void clearCache() {
    _users.clear();
    _searchResults.clear();
    _conversations.clear();
    _notifications.clear();
    _communities.clear();
    _clearError();
    notifyListeners();
  }

  // Check if current user is member of community
  bool isMemberOfCommunity(String communityId, BuildContext context) {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) return false;

    final community = _communities
        .where((c) => c.id == communityId)
        .firstOrNull;
    return community?.members.contains(currentUser.id) ?? false;
  }

  // Check if current user is following another user
  bool isFollowingUser(String userId, BuildContext context) {
    // Get current user from AuthProvider
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) return false;

    // Get user from the _users list
    final user = _users.where((u) => u.id == userId).firstOrNull;
    if (user == null) return false;

    // Check if current user's ID is in the user's followers list
    return user.followers.contains(currentUser.id);
  }
}
