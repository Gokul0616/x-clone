import 'package:flutter/foundation.dart';
import '../services/account_switch_service.dart';
import '../models/user_model.dart';

class AccountSwitchProvider with ChangeNotifier {
  List<StoredAccount> _storedAccounts = [];
  String? _currentAccountId;
  bool _isLoading = false;

  List<StoredAccount> get storedAccounts => _storedAccounts;
  String? get currentAccountId => _currentAccountId;
  bool get isLoading => _isLoading;
  
  // Get accounts excluding current user
  List<StoredAccount> get otherAccounts => _storedAccounts
      .where((account) => account.id != _currentAccountId)
      .toList();

  // Get current account
  StoredAccount? get currentAccount => _storedAccounts
      .cast<StoredAccount?>()
      .firstWhere((account) => account?.id == _currentAccountId, orElse: () => null);

  AccountSwitchProvider() {
    _loadStoredAccounts();
  }

  Future<void> _loadStoredAccounts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _storedAccounts = await AccountSwitchService.getStoredAccounts();
      _currentAccountId = await AccountSwitchService.getCurrentAccountId();
      
      // Sort by last used (most recent first)
      _storedAccounts.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    } catch (e) {
      print('Error loading stored accounts: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveAccount(String token, UserModel user) async {
    await AccountSwitchService.saveAccount(token, user);
    await _loadStoredAccounts();
  }

  Future<void> switchToAccount(String accountId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await AccountSwitchService.switchToAccount(accountId);
      _currentAccountId = accountId;
      await _loadStoredAccounts();
    } catch (e) {
      print('Error switching account: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> removeAccount(String accountId) async {
    await AccountSwitchService.removeAccount(accountId);
    await _loadStoredAccounts();
  }

  Future<void> clearAllAccounts() async {
    await AccountSwitchService.clearAllAccounts();
    await _loadStoredAccounts();
  }

  Future<void> refreshAccounts() async {
    await _loadStoredAccounts();
  }

  // Check if can add more accounts
  bool get canAddMoreAccounts => _storedAccounts.length < AccountSwitchService.maxAccounts;

  // Get display accounts for UI (max 4 for UI, rest in "more")
  List<StoredAccount> get displayAccounts => _storedAccounts.take(4).toList();
  
  bool get hasMoreAccounts => _storedAccounts.length > 4;
}