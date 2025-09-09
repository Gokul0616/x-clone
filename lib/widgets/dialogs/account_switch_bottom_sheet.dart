import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/account_switch_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tweet_provider.dart';
import '../../providers/user_provider.dart';
import '../../constants/app_colors.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';

class AccountSwitchBottomSheet extends StatefulWidget {
  const AccountSwitchBottomSheet({super.key});

  @override
  State<AccountSwitchBottomSheet> createState() => _AccountSwitchBottomSheetState();
}

class _AccountSwitchBottomSheetState extends State<AccountSwitchBottomSheet> {
  bool _isSwitching = false;

  @override
  void initState() {
    super.initState();
    // Refresh accounts when bottom sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountSwitchProvider>().refreshAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Accounts',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Current and other accounts
          Consumer2<AccountSwitchProvider, AuthProvider>(
            builder: (context, accountProvider, authProvider, child) {
              final currentUser = authProvider.currentUser;
              final allAccounts = accountProvider.storedAccounts;
              
              return Column(
                children: [
                  // Current account
                  if (currentUser != null)
                    _buildAccountTile(
                      context,
                      user: currentUser,
                      isCurrentUser: true,
                      onTap: () => Navigator.pop(context),
                    ),
                  
                  // Other accounts
                  ...allAccounts
                      .where((account) => account.id != accountProvider.currentAccountId)
                      .map((account) => _buildAccountTile(
                            context,
                            user: account.user,
                            isCurrentUser: false,
                            onTap: () => _switchAccount(context, account.id),
                          )),
                ],
              );
            },
          ),
          
          const Divider(height: 1),
          
          // Action buttons
          _buildActionButton(
            context,
            icon: Icons.person_add_outlined,
            title: 'Create a new account',
            onTap: () => _navigateToRegister(context),
          ),
          
          _buildActionButton(
            context,
            icon: Icons.login_outlined,
            title: 'Add an existing account',
            onTap: () => _navigateToLogin(context),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAccountTile(
    BuildContext context, {
    required user,
    required bool isCurrentUser,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundImage: user.profileImageUrl != null
            ? NetworkImage(user.profileImageUrl!)
            : null,
        child: user.profileImageUrl == null
            ? Text(
                user.displayName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        user.displayName,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text('@${user.username}'),
      trailing: isCurrentUser
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            )
          : _isSwitching
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
      onTap: _isSwitching ? null : onTap,
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          side: BorderSide(
            color: theme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _switchAccount(BuildContext context, String accountId) async {
    if (_isSwitching) return;
    
    setState(() {
      _isSwitching = true;
    });

    try {
      // Switch account in account provider
      await context.read<AccountSwitchProvider>().switchToAccount(accountId);
      
      // Reload user in auth provider
      await context.read<AuthProvider>().loadUserFromStorage();
      
      // Update tweet provider with new user
      final newUser = context.read<AuthProvider>().currentUser;
      if (newUser != null) {
        context.read<TweetProvider>().setCurrentUserId(newUser.id);
      }
      
      // Clear all cached data
      context.read<TweetProvider>().clearCache();
      context.read<UserProvider>().clearCache();
      context.read<MessageProvider>().clearCache();
      
      // Close bottom sheet
      if (mounted) {
        Navigator.pop(context);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to ${newUser?.displayName ?? 'account'}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch account: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isSwitching = false;
      });
    }
  }

  void _navigateToRegister(BuildContext context) async {
    Navigator.pop(context);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(isAddingAccount: true),
      ),
    );
    // Refresh accounts after returning
    if (mounted) {
      context.read<AccountSwitchProvider>().refreshAccounts();
    }
  }

  void _navigateToLogin(BuildContext context) async {
    Navigator.pop(context);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(isAddingAccount: true),
      ),
    );
    // Refresh accounts after returning
    if (mounted) {
      context.read<AccountSwitchProvider>().refreshAccounts();
    }
  }
}