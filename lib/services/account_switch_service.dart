import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

class StoredAccount {
  final String id;
  final String token;
  final UserModel user;
  final DateTime lastUsed;

  StoredAccount({
    required this.id,
    required this.token,
    required this.user,
    required this.lastUsed,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'token': token,
      'user': user.toJson(),
      'lastUsed': lastUsed.toIso8601String(),
    };
  }

  factory StoredAccount.fromJson(Map<String, dynamic> json) {
    return StoredAccount(
      id: json['id'],
      token: json['token'],
      user: UserModel.fromJson(json['user']),
      lastUsed: DateTime.parse(json['lastUsed']),
    );
  }

  StoredAccount copyWith({
    String? id,
    String? token,
    UserModel? user,
    DateTime? lastUsed,
  }) {
    return StoredAccount(
      id: id ?? this.id,
      token: token ?? this.token,
      user: user ?? this.user,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
}

class AccountSwitchService {
  static const String _accountsKey = 'stored_accounts';
  static const String _currentAccountKey = 'current_account_id';
  static const int maxAccounts = 5;

  // Save account after login
  static Future<void> saveAccount(String token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing accounts
    final accounts = await getStoredAccounts();
    
    // Check if account already exists
    final existingIndex = accounts.indexWhere((account) => account.user.id == user.id);
    
    final newAccount = StoredAccount(
      id: user.id,
      token: token,
      user: user,
      lastUsed: DateTime.now(),
    );

    if (existingIndex != -1) {
      // Update existing account
      accounts[existingIndex] = newAccount;
    } else {
      // Add new account
      if (accounts.length >= maxAccounts) {
        // Remove oldest account if limit reached
        accounts.sort((a, b) => a.lastUsed.compareTo(b.lastUsed));
        accounts.removeAt(0);
      }
      accounts.add(newAccount);
    }

    // Save accounts
    final accountsJson = accounts.map((account) => account.toJson()).toList();
    await prefs.setString(_accountsKey, json.encode(accountsJson));
    
    // Set as current account
    await prefs.setString(_currentAccountKey, user.id);
  }

  // Get all stored accounts
  static Future<List<StoredAccount>> getStoredAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accountsString = prefs.getString(_accountsKey);
    
    if (accountsString == null) return [];
    
    try {
      final accountsList = json.decode(accountsString) as List;
      return accountsList.map((account) => StoredAccount.fromJson(account)).toList();
    } catch (e) {
      print('Error loading stored accounts: $e');
      return [];
    }
  }

  // Switch to account
  static Future<void> switchToAccount(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await getStoredAccounts();
    
    final accountIndex = accounts.indexWhere((account) => account.id == accountId);
    if (accountIndex == -1) return;

    // Update last used time
    accounts[accountIndex] = accounts[accountIndex].copyWith(lastUsed: DateTime.now());
    
    // Save updated accounts
    final accountsJson = accounts.map((account) => account.toJson()).toList();
    await prefs.setString(_accountsKey, json.encode(accountsJson));
    
    // Set as current account
    await prefs.setString(_currentAccountKey, accountId);
    
    // Store current user and token for compatibility
    final account = accounts[accountIndex];
    await prefs.setString('current_user', json.encode(account.user.toJson()));
    await prefs.setString('auth_token', account.token);
  }

  // Get current account ID
  static Future<String?> getCurrentAccountId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentAccountKey);
  }

  // Remove account
  static Future<void> removeAccount(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await getStoredAccounts();
    
    accounts.removeWhere((account) => account.id == accountId);
    
    final accountsJson = accounts.map((account) => account.toJson()).toList();
    await prefs.setString(_accountsKey, json.encode(accountsJson));
    
    // If removed account was current, clear current
    final currentId = await getCurrentAccountId();
    if (currentId == accountId) {
      await prefs.remove(_currentAccountKey);
      await prefs.remove('current_user');
      await prefs.remove('auth_token');
    }
  }

  // Clear all accounts
  static Future<void> clearAllAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accountsKey);
    await prefs.remove(_currentAccountKey);
    await prefs.remove('current_user');
    await prefs.remove('auth_token');
  }

  // Get account by ID
  static Future<StoredAccount?> getAccountById(String accountId) async {
    final accounts = await getStoredAccounts();
    try {
      return accounts.firstWhere((account) => account.id == accountId);
    } catch (e) {
      return null;
    }
  }
}