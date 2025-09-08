import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/story_model.dart';
import 'api_service.dart';

class StoryService {
  final ApiService _apiService = ApiService();

  // Get stories from following users
  Future<List<StoryModel>> getFollowingStories() async {
    try {
      final response = await _apiService.get('/stories/following');

      if (response['status'] == 'success') {
        final List<dynamic> storiesJson = response['data'] ?? [];
        return storiesJson.map((json) => StoryModel.fromJson(json)).toList();
      }

      throw Exception(response['message'] ?? 'Failed to load stories');
    } catch (e) {
      print('Error loading stories: $e');
      // Return dummy data for development
      return _getDummyStories();
    }
  }

  // Get user's stories
  Future<List<StoryModel>> getUserStories(String userId) async {
    try {
      final response = await _apiService.get('/stories/user/$userId');

      if (response['status'] == 'success') {
        final List<dynamic> storiesJson = response['data'] ?? [];
        return storiesJson.map((json) => StoryModel.fromJson(json)).toList();
      }

      throw Exception(response['message'] ?? 'Failed to load user stories');
    } catch (e) {
      print('Error loading user stories: $e');
      return [];
    }
  }

  // Upload new story
  Future<StoryModel?> uploadStory({
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
      Map<String, dynamic> storyData = {
        'type': type.index,
        'textContent': textContent,
        'backgroundColor': backgroundColor,
        'fontFamily': fontFamily,
        'fontSize': fontSize,
        'textColor': textColor,
        'privacy': privacy.index,
        'mentions': mentions,
        'stickers': stickers.map((s) => s.toJson()).toList(),
        'filters': filters,
      };

      // If there's a media file, upload it first
      if (mediaPath != null && File(mediaPath).existsSync()) {
        final mediaUrl = await _uploadMedia(mediaPath);
        if (mediaUrl != null) {
          storyData['mediaUrl'] = mediaUrl;
        }
      }

      final response = await _apiService.post('/stories', storyData);

      if (response['status'] == 'success') {
        return StoryModel.fromJson(response['data']);
      }

      throw Exception(response['message'] ?? 'Failed to upload story');
    } catch (e) {
      print('Error uploading story: $e');

      // Return dummy story for development
      return StoryModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'current_user_id',
        type: type,
        mediaUrl: mediaPath,
        textContent: textContent,
        backgroundColor: backgroundColor,
        fontFamily: fontFamily,
        fontSize: fontSize,
        textColor: textColor,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        privacy: privacy,
        mentions: mentions,
        stickers: stickers,
        filters: filters,
      );
    }
  }

  // Upload media file
  Future<String?> _uploadMedia(String filePath) async {
    try {
      final file = File(filePath);
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '${_apiService.baseUrl}${_apiService.apiVersion}/upload/story-media',
        ),
      );

      // Add headers
      final headers = await _apiService.getHeaders();
      request.headers.addAll(headers);

      // Add file
      request.files.add(await http.MultipartFile.fromPath('media', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return responseData['data']['url'];
        }
      }

      return null;
    } catch (e) {
      print('Error uploading media: $e');
      return null;
    }
  }

  // Mark story as viewed
  Future<void> markStoryAsViewed(String storyId) async {
    try {
      await _apiService.post('/stories/$storyId/view', {});
    } catch (e) {
      print('Error marking story as viewed: $e');
    }
  }

  // React to story
  Future<void> reactToStory(String storyId, String emoji) async {
    try {
      await _apiService.post('/stories/$storyId/react', {'emoji': emoji});
    } catch (e) {
      print('Error reacting to story: $e');
    }
  }

  // Delete story
  Future<bool> deleteStory(String storyId) async {
    try {
      final response = await _apiService.delete('/stories/$storyId');
      return response['status'] == 'success';
    } catch (e) {
      print('Error deleting story: $e');
      return false;
    }
  }

  // Get user highlights
  Future<List<StoryHighlight>> getUserHighlights(String userId) async {
    try {
      final response = await _apiService.get('/stories/highlights/$userId');

      if (response['status'] == 'success') {
        final List<dynamic> highlightsJson = response['data'] ?? [];
        return highlightsJson
            .map((json) => StoryHighlight.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error loading highlights: $e');
      return [];
    }
  }

  // Create highlight
  Future<StoryHighlight?> createHighlight({
    required String name,
    required List<String> storyIds,
    String? coverImageUrl,
  }) async {
    try {
      final response = await _apiService.post('/stories/highlights', {
        'name': name,
        'storyIds': storyIds,
        'coverImageUrl': coverImageUrl,
      });

      if (response['status'] == 'success') {
        return StoryHighlight.fromJson(response['data']);
      }

      return null;
    } catch (e) {
      print('Error creating highlight: $e');
      return null;
    }
  }

  // Get story analytics
  Future<Map<String, dynamic>> getStoryAnalytics(String storyId) async {
    try {
      final response = await _apiService.get('/stories/$storyId/analytics');

      if (response['status'] == 'success') {
        return response['data'];
      }

      return {};
    } catch (e) {
      print('Error loading story analytics: $e');
      return {};
    }
  }

  // Get dummy stories for development
  List<StoryModel> _getDummyStories() {
    return [
      StoryModel(
        id: '1',
        userId: 'user1',
        type: StoryType.image,
        mediaUrl: 'https://picsum.photos/400/600?random=1',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        expiresAt: DateTime.now().add(const Duration(hours: 22)),
        viewedBy: ['user2', 'user3'],
      ),
      StoryModel(
        id: '2',
        userId: 'user2',
        type: StoryType.text,
        textContent: 'Good morning! ☀️',
        backgroundColor: '#FF6B6B',
        fontSize: 24.0,
        textColor: '#FFFFFF',
        fontFamily: 'Chirp',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        expiresAt: DateTime.now().add(const Duration(hours: 23)),
        viewedBy: ['user1'],
      ),
      StoryModel(
        id: '3',
        userId: 'user3',
        type: StoryType.video,
        mediaUrl:
            'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        expiresAt: DateTime.now().add(const Duration(hours: 23, minutes: 30)),
        viewedBy: [],
      ),
    ];
  }
}
