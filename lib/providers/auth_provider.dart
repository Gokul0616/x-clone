import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/account_switch_service.dart';
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
      final userJson = prefs.getString('current_user'); // Use consistent key
      final token = prefs.getString('auth_token');
      
      if (userJson != null && token != null) {
        final userData = json.decode(userJson);
        _currentUser = UserModel.fromJson(userData);
        _isLoggedIn = true;
        
        // Update API service token
        _apiService.setAuthToken(token);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user from storage: $e');
    }
  }

  // Public method to load user from storage (for account switching)
  Future<void> loadUserFromStorage() async {
    await _loadUserFromStorage();
  }

  // Save user to local storage
  Future<void> _saveUserToStorage(UserModel user, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = json.encode(user.toJson());
      await prefs.setString('current_user', userJson);
      await prefs.setString('auth_token', token);
      
      // Update API service token
      _apiService.setAuthToken(token);
    } catch (e) {
      print('Error saving user to storage: $e');
    }
  }

  // Clear user from local storage
  Future<void> _clearUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
      await prefs.remove('auth_token');
      
      // Clear API service token
      _apiService.clearAuthToken();
    } catch (e) {
      print('Error clearing user from storage: $e');
    }
  }

  // Login
  Future<bool> login(String email, String password, {bool isAddingAccount = false}) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _apiService.login(email, password);
      
      if (result != null && result['user'] != null && result['token'] != null) {
        final user = UserModel.fromJson(result['user']);
        final token = result['token'];
        
        _currentUser = user;
        _isLoggedIn = true;
        await _saveUserToStorage(user, token);
        
        // Save account for switching
        await AccountSwitchService.saveAccount(token, user);
        
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
  Future<bool> register(String email, String password, String username, String displayName, {bool isAddingAccount = false}) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _apiService.register(email, password, username, displayName);
      
      if (result != null && result['user'] != null && result['token'] != null) {
        final user = UserModel.fromJson(result['user']);
        final token = result['token'];
        
        _currentUser = user;
        _isLoggedIn = true;
        await _saveUserToStorage(user, token);
        
        // Save account for switching
        await AccountSwitchService.saveAccount(token, user);
        
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

      // Get current token and save updated user
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      await _saveUserToStorage(_currentUser!, token);
      
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
        
        // Get current token and save updated user
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token') ?? '';
        await _saveUserToStorage(_currentUser!, token);
        
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

  // Get current user ID
  String? getCurrentUserId() {
    return _currentUser?.id;
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