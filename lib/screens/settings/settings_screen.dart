import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
      ),
      body: ListView(
        children: [
          // Account section
          _buildSectionHeader(context, 'Account'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundImage: authProvider.currentUser?.profileImageUrl != null
                        ? NetworkImage(authProvider.currentUser!.profileImageUrl!)
                        : null,
                    child: authProvider.currentUser?.profileImageUrl == null
                        ? Text(
                            authProvider.currentUser?.displayName.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  title: Text(authProvider.currentUser?.displayName ?? 'User'),
                  subtitle: Text('@${authProvider.currentUser?.username ?? 'username'}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Account settings coming soon!')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: Text(AppStrings.privacyAndSafety),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy settings coming soon!')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security_outlined),
                  title: const Text('Security'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Security settings coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Appearance section
          _buildSectionHeader(context, AppStrings.appearance),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  ),
                  title: const Text('Theme'),
                  subtitle: Text(themeProvider.themeModeDisplayName),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showThemeDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.text_fields_outlined),
                  title: const Text('Text size'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Text size settings coming soon!')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.accessibility_outlined),
                  title: Text(AppStrings.accessibility),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Accessibility settings coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Notifications section
          _buildSectionHeader(context, AppStrings.notificationsSettings),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Push notifications'),
                  trailing: Switch(
                    value: true, // This would be managed by a NotificationProvider
                    onChanged: (value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification settings coming soon!')),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email notifications'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email settings coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Support section
          _buildSectionHeader(context, 'Support'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help Center'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help Center coming soon!')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: const Text('Send feedback'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feedback feature coming soon!')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Danger zone
          _buildSectionHeader(context, 'Account Actions'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout_outlined, color: AppColors.errorColor),
                  title: const Text('Log out', style: TextStyle(color: AppColors.errorColor)),
                  onTap: () => _showLogoutDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.errorColor),
                  title: const Text('Delete account', style: TextStyle(color: AppColors.errorColor)),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Delete account feature coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // App version
          Center(
            child: Text(
              '${AppStrings.appName} v${AppConstants.appVersion}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.brightness == Brightness.dark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingLarge,
        AppConstants.paddingMedium,
        AppConstants.paddingLarge,
        AppConstants.paddingSmall,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((themeMode) {
            return RadioListTile<ThemeMode>(
              title: Text(themeProvider.getThemeModeDisplayName(themeMode)),
              value: themeMode,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppStrings.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: Icon(
        Icons.electric_bolt_rounded,
        size: 48,
        color: AppColors.primaryBlue,
      ),
      children: [
        const Text('A Twitter clone built with Flutter'),
        const SizedBox(height: 16),
        const Text('Features:'),
        const Text('• Post and reply to tweets'),
        const Text('• Follow users and join communities'),
        const Text('• Real-time notifications'),
        const Text('• Dark and light themes'),
        const Text('• Responsive design'),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Close settings screen
              context.read<AuthProvider>().logout();
            },
            child: Text(
              AppStrings.logout,
              style: const TextStyle(color: AppColors.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}