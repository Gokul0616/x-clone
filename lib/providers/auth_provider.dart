import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../constants/app_constants.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isLoggedIn = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;

  final ApiService _apiService = ApiService();

  AuthProvider() {
    _loadUserFromStorage();
  }

  // Load user from local storage
  Future<void> _loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.userKey);
      
      if (userJson != null) {
        final userData = json.decode(userJson);
        _currentUser = UserModel.fromJson(userData);
        _isLoggedIn = true;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user from storage: $e');
    }
  }

  // Save user to local storage
  Future<void> _saveUserToStorage(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = json.encode(user.toJson());
      await prefs.setString(AppConstants.userKey, userJson);
    } catch (e) {
      print('Error saving user to storage: $e');
    }
  }

  // Clear user from local storage
  Future<void> _clearUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userKey);
      await prefs.remove(AppConstants.tokenKey);
    } catch (e) {
      print('Error clearing user from storage: $e');
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _apiService.login(email, password);
      
      if (user != null) {
        _currentUser = user;
        _isLoggedIn = true;
        await _saveUserToStorage(user);
        
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError('Invalid email or password');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Register
  Future<bool> register(String email, String password, String username, String displayName) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _apiService.register(email, password, username, displayName);
      
      if (user != null) {
        _currentUser = user;
        _isLoggedIn = true;
        await _saveUserToStorage(user);
        
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError('Registration failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    _isLoggedIn = false;
    await _clearUserFromStorage();
    notifyListeners();
  }

  // Update user profile
  Future<bool> updateProfile({
    String? displayName,
    String? bio,
    String? location,
    String? website,
    String? profileImageUrl,
    String? bannerImageUrl,
  }) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    _clearError();

    try {
      // In a real app, this would make an API call
      _currentUser = _currentUser!.copyWith(
        displayName: displayName ?? _currentUser!.displayName,
        bio: bio ?? _currentUser!.bio,
        location: location ?? _currentUser!.location,
        website: website ?? _currentUser!.website,
        profileImageUrl: profileImageUrl ?? _currentUser!.profileImageUrl,
        bannerImageUrl: bannerImageUrl ?? _currentUser!.bannerImageUrl,
      );

      await _saveUserToStorage(_currentUser!);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Profile update failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Follow/Unfollow user
  Future<bool> followUser(String userId) async {
    if (_currentUser == null) return false;

    try {
      final success = await _apiService.followUser(userId);
      
      if (success) {
        // Update local user data
        final following = List<String>.from(_currentUser!.following);
        if (following.contains(userId)) {
          following.remove(userId);
        } else {
          following.add(userId);
        }
        
        _currentUser = _currentUser!.copyWith(
          following: following,
          followingCount: following.length,
        );
        
        await _saveUserToStorage(_currentUser!);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Follow operation failed: ${e.toString()}');
      return false;
    }
  }

  // Check if current user is following another user
  bool isFollowing(String userId) {
    return _currentUser?.following.contains(userId) ?? false;
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
}