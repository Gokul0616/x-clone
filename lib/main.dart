import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/tweet_provider.dart';
import 'providers/user_provider.dart';
import 'providers/marketplace_provider.dart';
import 'providers/bookmarks_provider.dart';
import 'providers/story_provider.dart';
import 'providers/account_switch_provider.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/home/main_screen.dart';
import 'utils/themes.dart';
import 'constants/app_strings.dart';

void main() {
  runApp(const TwitterApp());
}

class TwitterApp extends StatelessWidget {
  const TwitterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AccountSwitchProvider()),
        ChangeNotifierProvider(create: (_) => TweetProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => MarketplaceProvider()),
        ChangeNotifierProvider(create: (_) => BookmarksProvider()),
        ChangeNotifierProvider(create: (_) => StoryProvider()),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, child) {
          // Update tweet provider with current user ID when auth state changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (authProvider.currentUser != null) {
              context.read<TweetProvider>().setCurrentUserId(authProvider.currentUser!.id);
            }
          });
          
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeProvider.themeMode,
            home: authProvider.isLoggedIn
                ? const MainScreen()
                : const AuthWrapper(),
          );
        },
      ),
    );
  }
}
