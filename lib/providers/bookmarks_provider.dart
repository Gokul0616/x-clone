import 'package:flutter/foundation.dart';
import '../models/tweet_model.dart';
import '../models/product_model.dart';
import '../models/service_model.dart';

class BookmarksProvider with ChangeNotifier {
  List<TweetModel> _bookmarkedTweets = [];
  List<ProductModel> _bookmarkedProducts = [];
  List<ServiceModel> _bookmarkedServices = [];
  bool _isLoading = false;
  String? _error;

  List<TweetModel> get bookmarkedTweets => _bookmarkedTweets;
  List<ProductModel> get bookmarkedProducts => _bookmarkedProducts;
  List<ServiceModel> get bookmarkedServices => _bookmarkedServices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load bookmarks
  Future<void> loadBookmarks() async {
    _setLoading(true);
    _clearError();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Load mock data or from local storage
      _bookmarkedTweets = []; // Load from storage
      _bookmarkedProducts = []; // Load from storage
      _bookmarkedServices = []; // Load from storage
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load bookmarks: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Tweet bookmarks
  void bookmarkTweet(TweetModel tweet) {
    if (!_bookmarkedTweets.any((t) => t.id == tweet.id)) {
      _bookmarkedTweets.insert(0, tweet);
      notifyListeners();
      // Save to local storage
    }
  }

  void unbookmarkTweet(String tweetId) {
    _bookmarkedTweets.removeWhere((tweet) => tweet.id == tweetId);
    notifyListeners();
    // Update local storage
  }

  bool isTweetBookmarked(String tweetId) {
    return _bookmarkedTweets.any((tweet) => tweet.id == tweetId);
  }

  // Product bookmarks
  void bookmarkProduct(ProductModel product) {
    if (!_bookmarkedProducts.any((p) => p.id == product.id)) {
      _bookmarkedProducts.insert(0, product);
      notifyListeners();
      // Save to local storage
    }
  }

  void unbookmarkProduct(String productId) {
    _bookmarkedProducts.removeWhere((product) => product.id == productId);
    notifyListeners();
    // Update local storage
  }

  bool isProductBookmarked(String productId) {
    return _bookmarkedProducts.any((product) => product.id == productId);
  }

  // Service bookmarks
  void bookmarkService(ServiceModel service) {
    if (!_bookmarkedServices.any((s) => s.id == service.id)) {
      _bookmarkedServices.insert(0, service);
      notifyListeners();
      // Save to local storage
    }
  }

  void unbookmarkService(String serviceId) {
    _bookmarkedServices.removeWhere((service) => service.id == serviceId);
    notifyListeners();
    // Update local storage
  }

  bool isServiceBookmarked(String serviceId) {
    return _bookmarkedServices.any((service) => service.id == serviceId);
  }

  // Clear all bookmarks
  void clearAllBookmarks() {
    _bookmarkedTweets.clear();
    _bookmarkedProducts.clear();
    _bookmarkedServices.clear();
    notifyListeners();
    // Clear local storage
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

  void clearError() {
    _clearError();
    notifyListeners();
  }
}