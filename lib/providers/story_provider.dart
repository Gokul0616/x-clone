import 'package:flutter/material.dart';
import '../models/story_model.dart';
import '../models/user_model.dart';
import '../services/story_service.dart';
import '../services/api_service.dart';

class StoryProvider with ChangeNotifier {
  final StoryService _storyService = StoryService();
  final ApiService _apiService = ApiService();

  List<StoryModel> _stories = [];
  List<StoryHighlight> _highlights = [];
  List<UserModel> _usersWithStories = [];
  bool _isLoading = false;
  bool _isUploadingStory = false;
  String? _error;
  StoryModel? _currentStory;
  int _currentStoryIndex = 0;

  // Getters
  List<StoryModel> get stories => _stories;
  List<StoryHighlight> get highlights => _highlights;
  List<UserModel> get usersWithStories => _usersWithStories;
  bool get isLoading => _isLoading;
  bool get isUploadingStory => _isUploadingStory;
  String? get error => _error;
  StoryModel? get currentStory => _currentStory;
  int get currentStoryIndex => _currentStoryIndex;

  // Load stories from following users
  Future<void> loadStories() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final stories = await _storyService.getFollowingStories();
      _stories = stories.where((story) => !story.isExpired).toList();
      
      // Group stories by user
      final Map<String, List<StoryModel>> storiesByUser = {};
      for (final story in _stories) {
        if (!storiesByUser.containsKey(story.userId)) {
          storiesByUser[story.userId] = [];
        }
        storiesByUser[story.userId]!.add(story);
      }

      // Create users with stories list
      _usersWithStories = storiesByUser.keys
          .map((userId) => storiesByUser[userId]!.first.user!)
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get stories for specific user
  List<StoryModel> getStoriesForUser(String userId) {
    return _stories.where((story) => story.userId == userId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  // Upload new story
  Future<bool> uploadStory({
    required StoryType type,
    String? mediaPath,
    String? textContent,
    String? backgroundColor,
    String? fontFamily,
    double? fontSize,
    String? textColor,
    StoryPrivacy privacy = StoryPrivacy.everyone,
    List<String> mentions = const [],
    List<StorySticker> stickers = const [],
    Map<String, dynamic>? filters,
  }) async {
    try {
      _isUploadingStory = true;
      _error = null;
      notifyListeners();

      final story = await _storyService.uploadStory(
        type: type,
        mediaPath: mediaPath,
        textContent: textContent,
        backgroundColor: backgroundColor,
        fontFamily: fontFamily,
        fontSize: fontSize,
        textColor: textColor,
        privacy: privacy,
        mentions: mentions,
        stickers: stickers,
        filters: filters,
      );

      if (story != null) {
        _stories.insert(0, story);
        await loadStories(); // Refresh to get updated user list
        _isUploadingStory = false;
        notifyListeners();
        return true;
      }

      _isUploadingStory = false;
      _error = 'Failed to upload story';
      notifyListeners();
      return false;
    } catch (e) {
      _isUploadingStory = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Mark story as viewed
  Future<void> markStoryAsViewed(String storyId) async {
    try {
      await _storyService.markStoryAsViewed(storyId);
      
      // Update local story
      final storyIndex = _stories.indexWhere((s) => s.id == storyId);
      if (storyIndex != -1) {
        final currentUserId = await _getCurrentUserId();
        if (currentUserId != null && 
            !_stories[storyIndex].viewedBy.contains(currentUserId)) {
          _stories[storyIndex] = _stories[storyIndex].copyWith(
            viewedBy: [..._stories[storyIndex].viewedBy, currentUserId],
          );
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error marking story as viewed: $e');
    }
  }

  // React to story
  Future<void> reactToStory(String storyId, String emoji) async {
    try {
      await _storyService.reactToStory(storyId, emoji);
      
      // Update local story
      final storyIndex = _stories.indexWhere((s) => s.id == storyId);
      if (storyIndex != -1) {
        final currentUserId = await _getCurrentUserId();
        if (currentUserId != null) {
          final reaction = StoryReaction(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: currentUserId,
            emoji: emoji,
            createdAt: DateTime.now(),
          );
          
          _stories[storyIndex] = _stories[storyIndex].copyWith(
            reactions: [..._stories[storyIndex].reactions, reaction],
          );
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Delete story
  Future<bool> deleteStory(String storyId) async {
    try {
      final success = await _storyService.deleteStory(storyId);
      if (success) {
        _stories.removeWhere((story) => story.id == storyId);
        await loadStories(); // Refresh user list
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Load user highlights
  Future<void> loadHighlights(String userId) async {
    try {
      _highlights = await _storyService.getUserHighlights(userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Create highlight
  Future<bool> createHighlight({
    required String name,
    required List<String> storyIds,
    String? coverImageUrl,
  }) async {
    try {
      final highlight = await _storyService.createHighlight(
        name: name,
        storyIds: storyIds,
        coverImageUrl: coverImageUrl,
      );
      
      if (highlight != null) {
        _highlights.add(highlight);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Set current story for viewing
  void setCurrentStory(StoryModel story, int index) {
    _currentStory = story;
    _currentStoryIndex = index;
    notifyListeners();
  }

  // Clear current story
  void clearCurrentStory() {
    _currentStory = null;
    _currentStoryIndex = 0;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Check if user has viewed story
  bool hasUserViewedStory(String storyId, String? userId) {
    if (userId == null) return false;
    final story = _stories.firstWhere(
      (s) => s.id == storyId,
      orElse: () => throw Exception('Story not found'),
    );
    return story.viewedBy.contains(userId);
  }

  // Get current user ID (you might want to get this from AuthProvider)
  Future<String?> _getCurrentUserId() async {
    // This should be implemented based on your auth system
    // For now, returning a dummy value
    return 'current_user_id';
  }

  // Get stories count for user
  int getStoriesCountForUser(String userId) {
    return _stories.where((story) => story.userId == userId).length;
  }

  // Check if user has unviewed stories
  bool hasUnviewedStories(String userId, String? currentUserId) {
    if (currentUserId == null) return false;
    final userStories = getStoriesForUser(userId);
    return userStories.any((story) => !story.viewedBy.contains(currentUserId));
  }

  @override
  void dispose() {
    super.dispose();
  }
}