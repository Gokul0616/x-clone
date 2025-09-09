import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/user_provider.dart';
import '../../providers/message_provider.dart';
import '../../models/message_model.dart' as messages;
import '../../constants/app_strings.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../widgets/story/stories_bar.dart';
import 'conversation_screen.dart';
import 'connections_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadConversations();
    });
  }

  Future<void> _handleRefresh() async {
    await context.read<UserProvider>().loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading && userProvider.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userProvider.error != null &&
              userProvider.conversations.isEmpty) {
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
                      userProvider.loadConversations();
                    },
                    child: Text(AppStrings.retry),
                  ),
                ],
              ),
            );
          }

          if (userProvider.conversations.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: Column(
              children: [
                // Stories section at the top
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      const StoriesBar(),
                      Container(
                        height: 8,
                        color: Theme.of(context).dividerColor.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
                // Conversations list
                Expanded(
                  child: ListView.builder(
                    itemCount: userProvider.conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = userProvider.conversations[index];
                      return Column(
                        children: [
                          ConversationTile(
                            conversation: conversation,
                            onTap: () => _openConversation(conversation),
                          ),
                          if (index < userProvider.conversations.length - 1)
                            Divider(
                              height: 1,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewMessageDialog(),
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Stories section at the top when no conversations
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              const StoriesBar(),
              Container(
                height: 8,
                color: Theme.of(context).dividerColor.withOpacity(0.3),
              ),
            ],
          ),
        ),
        // Empty state content
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mail_outline,
                  size: 64,
                  color: theme.brightness == Brightness.dark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(height: 16),
                Text('No messages yet', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'When you send or receive messages, they\'ll show up here.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _showNewMessageDialog(),
                  child: Text(AppStrings.newMessage),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openConversation(messages.ConversationModel conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationScreen(conversation: conversation),
      ),
    );
  }

  void _showNewMessageDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('New message feature coming soon!')),
    );
  }
}

class ConversationTile extends StatelessWidget {
  final messages.ConversationModel conversation;
  final VoidCallback? onTap;

  const ConversationTile({super.key, required this.conversation, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const currentUserId = 'user_1'; // This should come from AuthProvider

    // Get the other participant (not current user)
    final otherParticipant = conversation.participantUsers
        .where((user) => user.id != currentUserId)
        .firstOrNull;

    final unreadCount = conversation.unreadCount;
    final hasUnread = unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: hasUnread
              ? (theme.brightness == Brightness.dark
                    ? AppColors.primaryBlue.withOpacity(0.05)
                    : AppColors.primaryBlue.withOpacity(0.03))
              : null,
        ),
        child: Row(
          children: [
            // Profile avatar
            CircleAvatar(
              radius: 24,
              backgroundImage: otherParticipant?.profileImageUrl != null
                  ? NetworkImage(otherParticipant!.profileImageUrl!)
                  : null,
              child: otherParticipant?.profileImageUrl == null
                  ? Text(
                      otherParticipant?.displayName
                              .substring(0, 1)
                              .toUpperCase() ??
                          'U',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Conversation info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Participant name
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherParticipant?.displayName ?? 'Unknown User',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: hasUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (otherParticipant?.isVerified == true)
                        Icon(
                          Icons.verified,
                          size: 16,
                          color: AppColors.verified,
                        ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  // Username
                  Text(
                    '@${otherParticipant?.username ?? 'unknown'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.brightness == Brightness.dark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Last message
                  if (conversation.lastMessage != null)
                    Text(
                      conversation.lastMessage!.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: hasUnread
                            ? (theme.brightness == Brightness.dark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight)
                            : (theme.brightness == Brightness.dark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                        fontWeight: hasUnread
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Right side - timestamp and unread indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Timestamp
                Text(
                  timeago.format(conversation.lastActivity, allowFromNow: true),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: hasUnread
                        ? AppColors.primaryBlue
                        : (theme.brightness == Brightness.dark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),

                const SizedBox(height: 4),

                // Unread count
                if (hasUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
