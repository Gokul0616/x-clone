import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/user_provider.dart';
import '../../providers/message_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/message_model.dart' as messages;
import '../../constants/app_strings.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import 'dart:async';

class ConversationScreen extends StatefulWidget {
  final messages.ConversationModel conversation;

  const ConversationScreen({super.key, required this.conversation});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeConversation();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    
    // Leave conversation when screen is disposed
    final messageProvider = context.read<MessageProvider>();
    messageProvider.leaveConversation(widget.conversation.id);
    
    super.dispose();
  }

  void _initializeConversation() {
    final messageProvider = context.read<MessageProvider>();
    
    // Initialize real-time messaging if not already done
    messageProvider.initializeRealTimeMessaging();
    
    // Join conversation for real-time updates
    messageProvider.joinConversation(widget.conversation.id);
    
    // Load messages
    messageProvider.loadMessages(widget.conversation.id, refresh: true);
    
    // Mark as read
    messageProvider.markConversationAsRead(widget.conversation.id);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTyping(String text) {
    final messageProvider = context.read<MessageProvider>();
    
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      messageProvider.startTyping();
    } else if (text.isEmpty && _isTyping) {
      _isTyping = false;
      messageProvider.stopTyping();
    }
    
    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        messageProvider.stopTyping();
      }
    });
    
    setState(() {});
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final messageProvider = context.read<MessageProvider>();
    final currentUserId = authProvider.currentUser?.id;

    if (currentUserId == null) return;

    // Get the other participant
    final otherParticipant = widget.conversation.participantUsers
        .where((user) => user.id != currentUserId)
        .firstOrNull;

    if (otherParticipant != null) {
      // Clear the input immediately for better UX
      _messageController.clear();
      
      // Stop typing indicator
      if (_isTyping) {
        _isTyping = false;
        messageProvider.stopTyping();
      }

      final success = await messageProvider.sendMessage(
        receiverId: otherParticipant.id,
        content: text,
      );

      if (success) {
        _scrollToBottom();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(messageProvider.error ?? 'Failed to send message'),
            backgroundColor: AppColors.errorColor,
          ),
        );
        
        // Restore text if sending failed
        _messageController.text = text;
      }
    }

    setState(() {});
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
