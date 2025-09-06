import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/user_provider.dart';
import '../../models/notification_model.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/tweet/tweet_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadNotifications();
    });
  }

  Future<void> _handleRefresh() async {
    await context.read<UserProvider>().loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading && userProvider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userProvider.error != null && userProvider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userProvider.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      userProvider.clearError();
                      userProvider.loadNotifications();
                    },
                    child: Text(AppStrings.retry),
                  ),
                ],
              ),
            );
          }

          if (userProvider.notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: Column(
              children: [
                // Mark all as read button
                if (userProvider.unreadNotificationsCount > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    child: TextButton(
                      onPressed: () {
                        userProvider.markAllNotificationsAsRead();
                      },
                      child: Text('Mark all as read (${userProvider.unreadNotificationsCount})'),
                    ),
                  ),
                
                // Notifications list
                Expanded(
                  child: ListView.builder(
                    itemCount: userProvider.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = userProvider.notifications[index];
                      return Column(
                        children: [
                          NotificationTile(
                            notification: notification,
                            onTap: () => _handleNotificationTap(notification),
                          ),
                          if (index < userProvider.notifications.length - 1)
                            Divider(
                              height: 1,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_outlined,
            size: 64,
            color: theme.brightness == Brightness.dark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'When someone likes, retweets, or replies to your tweets, you\'ll see it here.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.brightness == Brightness.dark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read
    context.read<UserProvider>().markNotificationAsRead(notification.id);
    
    // Navigate based on notification type
    switch (notification.type) {
      case 'follow':
        if (notification.fromUser != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(userId: notification.fromUser!.id),
            ),
          );
        }
        break;
      case 'like':
      case 'retweet':
      case 'reply':
      case 'quote':
        if (notification.tweet != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TweetDetailScreen(tweet: notification.tweet!),
            ),
          );
        }
        break;
      case 'mention':
        if (notification.tweet != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TweetDetailScreen(tweet: notification.tweet!),
            ),
          );
        }
        break;
    }
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: notification.isRead
              ? null
              : (theme.brightness == Brightness.dark
                  ? AppColors.primaryBlue.withOpacity(0.05)
                  : AppColors.primaryBlue.withOpacity(0.03)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getNotificationColor(notification.type).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: _getNotificationColor(notification.type),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info
                  if (notification.fromUser != null)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: notification.fromUser!.profileImageUrl != null
                              ? NetworkImage(notification.fromUser!.profileImageUrl!)
                              : null,
                          child: notification.fromUser!.profileImageUrl == null
                              ? Text(
                                  notification.fromUser!.displayName.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(fontSize: 10),
                                )
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            notification.fromUser!.displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (notification.fromUser!.isVerified)
                          Icon(
                            Icons.verified,
                            size: 14,
                            color: AppColors.verified,
                          ),
                      ],
                    ),
                  
                  const SizedBox(height: 4),
                  
                  // Notification message
                  Text(
                    notification.displayMessage,
                    style: theme.textTheme.bodyMedium,
                  ),
                  
                  // Tweet content (if applicable)
                  if (notification.tweet != null && notification.tweet!.content.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        notification.tweet!.content,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 4),
                  
                  // Timestamp
                  Text(
                    timeago.format(notification.createdAt, allowFromNow: true),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.brightness == Brightness.dark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            
            // Unread indicator
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'retweet':
        return Icons.repeat;
      case 'follow':
        return Icons.person_add;
      case 'reply':
        return Icons.reply;
      case 'mention':
        return Icons.alternate_email;
      case 'quote':
        return Icons.format_quote;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'like':
        return AppColors.likeColor;
      case 'retweet':
        return AppColors.retweetColor;
      case 'follow':
        return AppColors.primaryBlue;
      case 'reply':
        return AppColors.replyColor;
      case 'mention':
        return AppColors.primaryBlue;
      case 'quote':
        return AppColors.shareColor;
      default:
        return AppColors.primaryBlue;
    }
  }
}