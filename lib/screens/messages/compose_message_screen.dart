import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/message_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';

class ComposeMessageScreen extends StatefulWidget {
  final UserModel? recipient;

  const ComposeMessageScreen({super.key, this.recipient});

  @override
  State<ComposeMessageScreen> createState() => _ComposeMessageScreenState();
}

class _ComposeMessageScreenState extends State<ComposeMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  UserModel? _selectedUser;
  bool _isSearching = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    if (widget.recipient != null) {
      _selectedUser = widget.recipient;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // TODO: Implement user search
    // For now, we'll use mock data
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _searchResults = []; // This should be populated from search API
        _isSearching = false;
      });
    }
  }

  void _selectUser(UserModel user) {
    setState(() {
      _selectedUser = user;
      _searchController.clear();
      _searchResults = [];
    });
  }

  void _sendMessage() async {
    if (_selectedUser == null || _messageController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    final success = await context.read<MessageProvider>().sendMessage(
      receiverId: _selectedUser!.id,
      content: _messageController.text.trim(),
    );

    setState(() {
      _isSending = false;
    });

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message sent to ${_selectedUser!.displayName}'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to send message'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Message'),
        actions: [
          TextButton(
            onPressed: _selectedUser != null && 
                       _messageController.text.trim().isNotEmpty && 
                       !_isSending
                ? _sendMessage
                : null,
            child: _isSending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Recipient selection
          if (_selectedUser == null) ...[
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search people...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: _searchUsers,
              ),
            ),
            
            // Search results
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.all(AppConstants.paddingMedium),
                child: CircularProgressIndicator(),
              )
            else if (_searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.profileImageUrl != null
                            ? NetworkImage(user.profileImageUrl!)
                            : null,
                        child: user.profileImageUrl == null
                            ? Text(user.displayName.substring(0, 1).toUpperCase())
                            : null,
                      ),
                      title: Text(user.displayName),
                      subtitle: Text('@${user.username}'),
                      trailing: user.isVerified
                          ? Icon(Icons.verified, color: AppColors.primaryBlue)
                          : null,
                      onTap: () => _selectUser(user),
                    );
                  },
                ),
              )
            else if (_searchController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Text(
                  'No users found',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
              ),
          ] else ...[
            // Selected recipient
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Text('To: '),
                  Chip(
                    avatar: CircleAvatar(
                      backgroundImage: _selectedUser!.profileImageUrl != null
                          ? NetworkImage(_selectedUser!.profileImageUrl!)
                          : null,
                      child: _selectedUser!.profileImageUrl == null
                          ? Text(_selectedUser!.displayName.substring(0, 1).toUpperCase())
                          : null,
                    ),
                    label: Text(_selectedUser!.displayName),
                    onDeleted: () {
                      setState(() {
                        _selectedUser = null;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            // Message input
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    hintText: 'Start a message...',
                    border: InputBorder.none,
                  ),
                  textAlignVertical: TextAlignVertical.top,
                  onChanged: (text) {
                    setState(() {});
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}