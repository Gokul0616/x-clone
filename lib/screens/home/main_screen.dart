import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_colors.dart';
import 'home_screen.dart';
import '../search/search_screen.dart';
import '../notifications/notifications_screen.dart';
import '../messages/messages_screen.dart';
import '../spaces/spaces_screen.dart';
import '../../widgets/common/custom_drawer.dart';
import '../../widgets/common/compose_tweet_fab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const SpacesScreen(), // Changed from marketplace to spaces
    const NotificationsScreen(),
    const MessagesScreen(),
  ];

  final List<String> _appBarTitles = [
    AppStrings.home,
    AppStrings.search,
    AppStrings.communities, // This will be "Spaces"
    AppStrings.notifications,
    AppStrings.messages,
  ];

  @override
  void initState() {
    super.initState();

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadNotifications();
      context.read<UserProvider>().loadConversations();
      context.read<UserProvider>().loadCommunities();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Row(
          children: [
            // App logo
            Image.asset('assets/images/logo.png', height: 28, width: 28),
            const SizedBox(width: 8),
            Text(_appBarTitles[_selectedIndex]),
          ],
        ),
        leading: IconButton(
          icon: CircleAvatar(
            radius: 16,
            backgroundImage: authProvider.currentUser?.profileImageUrl != null
                ? NetworkImage(authProvider.currentUser!.profileImageUrl!)
                : null,
            child: authProvider.currentUser?.profileImageUrl == null
                ? Text(
                    authProvider.currentUser?.displayName
                            .substring(0, 1)
                            .toUpperCase() ??
                        'U',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          // Theme toggle
          IconButton(
            icon: Icon(
              context.watch<ThemeProvider>().isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: theme.brightness == Brightness.dark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: AppStrings.home,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: AppStrings.search,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                if (userProvider.unreadNotificationsCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.errorColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        userProvider.unreadNotificationsCount > 99
                            ? '99+'
                            : userProvider.unreadNotificationsCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (userProvider.unreadNotificationsCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.errorColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        userProvider.unreadNotificationsCount > 99
                            ? '99+'
                            : userProvider.unreadNotificationsCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: AppStrings.notifications,
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.mail_outlined),
                if (userProvider.unreadMessagesCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.errorColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        userProvider.unreadMessagesCount > 99
                            ? '99+'
                            : userProvider.unreadMessagesCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: Stack(
              children: [
                const Icon(Icons.mail),
                if (userProvider.unreadMessagesCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.errorColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        userProvider.unreadMessagesCount > 99
                            ? '99+'
                            : userProvider.unreadMessagesCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: AppStrings.messages,
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? const ComposeTweetFAB()
          : null,
    );
  }
}
