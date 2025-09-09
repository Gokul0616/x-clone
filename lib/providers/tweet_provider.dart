import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/tweet_model.dart';
import '../services/api_service.dart';

class TweetProvider with ChangeNotifier {
  List<TweetModel> _tweets = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreTweets = true;

  List<TweetModel> get tweets => _tweets;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMoreTweets => _hasMoreTweets;

  final ApiService _apiService = ApiService();

  // Load initial tweets
  Future<void> loadTweets({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreTweets = true;
      _tweets.clear();
    }

    _setLoading(true);
    _clearError();

    try {
      final newTweets = await _apiService.getTimeline(
        page: _currentPage,
        limit: 20,
      );

      if (refresh) {
        _tweets = newTweets;
      } else {
        _tweets.addAll(newTweets);
      }

      _hasMoreTweets = newTweets.length == 20;
      _currentPage++;

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load tweets: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Load more tweets (pagination)
  Future<void> loadMoreTweets() async {
    if (_isLoadingMore || !_hasMoreTweets) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final newTweets = await _apiService.getTimeline(
        page: _currentPage,
        limit: 20,
      );

      _tweets.addAll(newTweets);
      _hasMoreTweets = newTweets.length == 20;
      _currentPage++;

      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load more tweets: ${e.toString()}');
      _isLoadingMore = false;
    }
  }

  // Create new tweet
  Future<bool> createTweet(
    String content, {
    List<XFile>? images,
    String? replyToTweetId,
    String? quotedTweetId,
  }) async {
    _clearError();

    try {
      final newTweet = await _apiService.createTweet(
        content,
        images: images,
        replyToTweetId: replyToTweetId,
        quotedTweetId: quotedTweetId,
      );

      if (newTweet != null) {
        // Add to the beginning of the list if it's not a reply
        if (replyToTweetId == null) {
          _tweets.insert(0, newTweet);
        } else {
          // Update reply count for parent tweet
          _updateParentTweetReplies(replyToTweetId);
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to create tweet: ${e.toString()}');
      return false;
    }
  }

  // Like/unlike tweet
  Future<bool> toggleLikeTweet(String tweetId) async {
    try {
      final success = await _apiService.likeTweet(tweetId);

      if (success) {
        // Update local tweet data
        final tweetIndex = _tweets.indexWhere((tweet) => tweet.id == tweetId);
        if (tweetIndex != -1) {
          final tweet = _tweets[tweetIndex];
          final likedBy = List<String>.from(tweet.likedBy);

          // Assuming current user ID is available (you might need to get this from AuthProvider)
          const currentUserId = 'user_1'; // This should come from AuthProvider

          if (likedBy.contains(currentUserId)) {
            likedBy.remove(currentUserId);
          } else {
            likedBy.add(currentUserId);
          }

          _tweets[tweetIndex] = tweet.copyWith(
            likedBy: likedBy,
            likesCount: likedBy.length,
          );

          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to like tweet: ${e.toString()}');
      return false;
    }
  }

  // Retweet/unretweet tweet
  Future<bool> toggleRetweetTweet(String tweetId) async {
    try {
      final success = await _apiService.retweetTweet(tweetId);

      if (success) {
        // Update local tweet data
        final tweetIndex = _tweets.indexWhere((tweet) => tweet.id == tweetId);
        if (tweetIndex != -1) {
          final tweet = _tweets[tweetIndex];
          final retweetedBy = List<String>.from(tweet.retweetedBy);

          const currentUserId = 'user_1'; // This should come from AuthProvider

          if (retweetedBy.contains(currentUserId)) {
            retweetedBy.remove(currentUserId);
          } else {
            retweetedBy.add(currentUserId);
          }

          _tweets[tweetIndex] = tweet.copyWith(
            retweetedBy: retweetedBy,
            retweetsCount: retweetedBy.length,
          );

          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to retweet: ${e.toString()}');
      return false;
    }
  }

  // Get tweet by ID
  TweetModel? getTweetById(String tweetId) {
    try {
      return _tweets.firstWhere((tweet) => tweet.id == tweetId);
    } catch (e) {
      return null;
    }
  }

  // Get tweets by user
  List<TweetModel> getTweetsByUser(String userId) {
    return _tweets.where((tweet) => tweet.userId == userId).toList();
  }

  // Get replies for a tweet
  Future<List<TweetModel>> getTweetReplies(String tweetId) async {
    try {
      return await _apiService.getTweetReplies(tweetId);
    } catch (e) {
      _setError('Failed to load replies: ${e.toString()}');
      return [];
    }
  }

  // Search tweets
  List<TweetModel> searchTweets(String query) {
    return _tweets
        .where(
          (tweet) =>
              tweet.content.toLowerCase().contains(query.toLowerCase()) ||
              tweet.hashtags.any(
                (hashtag) =>
                    hashtag.toLowerCase().contains(query.toLowerCase()),
              ),
        )
        .toList();
  }

  // Get trending hashtags
  List<String> getTrendingHashtags() {
    final Map<String, int> hashtagCounts = {};

    for (final tweet in _tweets) {
      for (final hashtag in tweet.hashtags) {
        hashtagCounts[hashtag] = (hashtagCounts[hashtag] ?? 0) + 1;
      }
    }

    final sortedHashtags = hashtagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedHashtags.take(10).map((entry) => entry.key).toList();
  }

  // Update parent tweet replies count (for reply tweets)
  void _updateParentTweetReplies(String parentTweetId) {
    final parentIndex = _tweets.indexWhere(
      (tweet) => tweet.id == parentTweetId,
    );
    if (parentIndex != -1) {
      final parentTweet = _tweets[parentIndex];
      _tweets[parentIndex] = parentTweet.copyWith(
        repliesCount: parentTweet.repliesCount + 1,
      );
    }
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
    _tweets.clear();
    _currentPage = 1;
    _hasMoreTweets = true;
    _clearError();
    notifyListeners();
  }

  // Refresh tweets
  Future<void> refreshTweets() async {
    await loadTweets(refresh: true);
  }

  // Check if user liked a tweet
  bool isLikedByCurrentUser(String tweetId) {
    const currentUserId = 'user_1'; // This should come from AuthProvider
    final tweet = getTweetById(tweetId);
    return tweet?.likedBy.contains(currentUserId) ?? false;
  }

  // Check if user retweeted a tweet
  bool isRetweetedByCurrentUser(String tweetId) {
    const currentUserId = 'user_1'; // This should come from AuthProvider
    final tweet = getTweetById(tweetId);
    return tweet?.retweetedBy.contains(currentUserId) ?? false;
  }
}
