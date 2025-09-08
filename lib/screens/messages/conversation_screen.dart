import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/user_provider.dart';
import '../../models/message_model.dart' as messages;
import '../../constants/app_strings.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';

class ConversationScreen extends StatefulWidget {
  final messages.ConversationModel conversation;

  const ConversationScreen({super.key, required this.conversation});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<messages.MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final userProvider = context.read<UserProvider>();
    final messages = await userProvider.getMessagesForConversation(
      widget.conversation.id,
    );

    setState(() {
      _messages = messages;
      _isLoading = false;
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    const currentUserId = 'user_1'; // This should come from AuthProvider

    // Get the other participant
    final otherParticipant = widget.conversation.participantUsers
        .where((user) => user.id != currentUserId)
        .firstOrNull;

    if (otherParticipant != null) {
      final userProvider = context.read<UserProvider>();
      final success = await userProvider.sendMessage(otherParticipant.id, text);

      if (success) {
        _messageController.clear();
        await _loadMessages(); // Reload messages
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userProvider.error ?? 'Failed to send message'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }

    setState(() {
      _isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const currentUserId = 'user_1'; // This should come from AuthProvider

    // Get the other participant
    final otherParticipant = widget.conversation.participantUsers
        .where((user) => user.id != currentUserId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: otherParticipant?.profileImageUrl != null
                  ? NetworkImage(otherParticipant!.profileImageUrl!)
                  : null,
              child: otherParticipant?.profileImageUrl == null
                  ? Text(
                      otherParticipant?.displayName
                              .substring(0, 1)
                              .toUpperCase() ??
                          'U',
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherParticipant?.displayName ?? 'Unknown User',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@${otherParticipant?.username ?? 'unknown'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.brightness == Brightness.dark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Conversation info coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isFromCurrentUser =
                          message.senderId == currentUserId;
                      final showTimestamp =
                          index == 0 ||
                          _messages[index - 1].createdAt
                                  .difference(message.createdAt)
                                  .inMinutes
                                  .abs() >
                              5;

                      return MessageBubble(
                        message: message,
                        isFromCurrentUser: isFromCurrentUser,
                        showTimestamp: showTimestamp,
                      );
                    },
                  ),
          ),

          // Message input
          _buildMessageInput(),
        ],
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
            Icons.chat_bubble_outline,
            size: 64,
            color: theme.brightness == Brightness.dark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 16),
          Text('Start a conversation', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Send a message to get started.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.brightness == Brightness.dark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.brightness == Brightness.dark
                ? AppColors.borderDark
                : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: AppStrings.sendMessage,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              onChanged: (text) {
                setState(() {});
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _messageController.text.trim().isNotEmpty && !_isSending
                ? _sendMessage
                : null,
            icon: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: _messageController.text.trim().isNotEmpty
                  ? AppColors.primaryBlue
                  : null,
              foregroundColor: _messageController.text.trim().isNotEmpty
                  ? Colors.white
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final messages.MessageModel message;
  final bool isFromCurrentUser;
  final bool showTimestamp;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromCurrentUser,
    required this.showTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: isFromCurrentUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (showTimestamp)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                timeago.format(message.createdAt, allowFromNow: true),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),

        Container(
          margin: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: isFromCurrentUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isFromCurrentUser) ...[
                CircleAvatar(
                  radius: 12,
                  backgroundImage: message.sender?.profileImageUrl != null
                      ? NetworkImage(message.sender!.profileImageUrl!)
                      : null,
                  child: message.sender?.profileImageUrl == null
                      ? Text(
                          message.sender?.displayName
                                  .substring(0, 1)
                                  .toUpperCase() ??
                              'U',
                          style: const TextStyle(fontSize: 10),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
              ],

              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isFromCurrentUser
                        ? AppColors.primaryBlue
                        : (theme.brightness == Brightness.dark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isFromCurrentUser
                          ? Colors.white
                          : (theme.brightness == Brightness.dark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight),
                    ),
                  ),
                ),
              ),

              if (isFromCurrentUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 12,
                  backgroundImage: message.sender?.profileImageUrl != null
                      ? NetworkImage(message.sender!.profileImageUrl!)
                      : null,
                  child: message.sender?.profileImageUrl == null
                      ? Text(
                          message.sender?.displayName
                                  .substring(0, 1)
                                  .toUpperCase() ??
                              'U',
                          style: const TextStyle(fontSize: 10),
                        )
                      : null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
