import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/tweet_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/tweet_model.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';

class ComposeTweetScreen extends StatefulWidget {
  final TweetModel? replyToTweet;
  final TweetModel? quoteTweet;

  const ComposeTweetScreen({
    super.key,
    this.replyToTweet,
    this.quoteTweet,
  });

  @override
  State<ComposeTweetScreen> createState() => _ComposeTweetScreenState();
}

class _ComposeTweetScreenState extends State<ComposeTweetScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _selectedImages = [];
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    
    // Pre-fill reply text
    if (widget.replyToTweet != null) {
      _controller.text = '@${widget.replyToTweet!.user?.username ?? ''} ';
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canPost {
    final text = _controller.text.trim();
    return text.isNotEmpty && 
           text.length <= AppConstants.maxTweetLength && 
           !_isPosting;
  }

  int get _remainingCharacters {
    return AppConstants.maxTweetLength - _controller.text.length;
  }

  String get _screenTitle {
    if (widget.replyToTweet != null) return 'Reply';
    if (widget.quoteTweet != null) return 'Quote Tweet';
    return 'Tweet';
  }

  Future<void> _postTweet() async {
    if (!_canPost) return;

    setState(() {
      _isPosting = true;
    });

    final tweetProvider = context.read<TweetProvider>();
    
    final success = await tweetProvider.createTweet(
      _controller.text.trim(),
      imageUrls: _selectedImages,
      replyToTweetId: widget.replyToTweet?.id,
      quotedTweetId: widget.quoteTweet?.id,
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.replyToTweet != null 
                ? 'Reply posted!' 
                : 'Tweet posted!',
          ),
          backgroundColor: AppColors.successColor,
        ),
      );
    } else if (mounted) {
      setState(() {
        _isPosting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tweetProvider.error ?? 'Failed to post tweet'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= AppConstants.maxImagesPerTweet) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can only add up to ${AppConstants.maxImagesPerTweet} images'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImages.add(image.path);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = context.watch<AuthProvider>().currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
              vertical: 8,
            ),
            child: ElevatedButton(
              onPressed: _canPost ? _postTweet : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primaryBlue.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.replyToTweet != null ? 'Reply' : 'Tweet',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Reply indicator
          if (widget.replyToTweet != null) _buildReplyIndicator(),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                children: [
                  // User info and compose area
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile avatar
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: currentUser?.profileImageUrl != null
                            ? NetworkImage(currentUser!.profileImageUrl!)
                            : null,
                        child: currentUser?.profileImageUrl == null
                            ? Text(
                                currentUser?.displayName.substring(0, 1).toUpperCase() ?? 'U',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      
                      // Text input
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          maxLines: null,
                          maxLength: AppConstants.maxTweetLength,
                          decoration: InputDecoration(
                            hintText: widget.replyToTweet != null 
                                ? AppStrings.tweetYourReply
                                : AppStrings.whatsHappening,
                            border: InputBorder.none,
                            counterText: '',
                          ),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 18,
                          ),
                          onChanged: (text) {
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  // Selected images
                  if (_selectedImages.isNotEmpty) _buildSelectedImages(),
                  
                  // Quote tweet
                  if (widget.quoteTweet != null) _buildQuoteTweet(),
                  
                  const Spacer(),
                  
                  // Bottom toolbar
                  _buildBottomToolbar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyIndicator() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.brightness == Brightness.dark
                ? AppColors.borderDark
                : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: widget.replyToTweet!.user?.profileImageUrl != null
                ? NetworkImage(widget.replyToTweet!.user!.profileImageUrl!)
                : null,
            child: widget.replyToTweet!.user?.profileImageUrl == null
                ? Text(
                    widget.replyToTweet!.user?.displayName.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(fontSize: 12),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Replying to @${widget.replyToTweet!.user?.username ?? 'unknown'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImages() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            width: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: AssetImage(_selectedImages[index]), // In real app, use proper image loading
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuoteTweet() {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? AppColors.borderDark
              : AppColors.borderLight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundImage: widget.quoteTweet!.user?.profileImageUrl != null
                    ? NetworkImage(widget.quoteTweet!.user!.profileImageUrl!)
                    : null,
                child: widget.quoteTweet!.user?.profileImageUrl == null
                    ? Text(
                        widget.quoteTweet!.user?.displayName.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(fontSize: 10),
                      )
                    : null,
              ),
              const SizedBox(width: 6),
              Text(
                widget.quoteTweet!.user?.displayName ?? 'Unknown',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '@${widget.quoteTweet!.user?.username ?? 'unknown'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.quoteTweet!.content,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar() {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        // Media button
        IconButton(
          icon: const Icon(Icons.image_outlined),
          onPressed: _pickImage,
          color: AppColors.primaryBlue,
        ),
        
        // GIF button
        IconButton(
          icon: const Icon(Icons.gif_box_outlined),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('GIF feature coming soon!')),
            );
          },
          color: AppColors.primaryBlue,
        ),
        
        // Poll button
        IconButton(
          icon: const Icon(Icons.poll_outlined),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Poll feature coming soon!')),
            );
          },
          color: AppColors.primaryBlue,
        ),
        
        // Emoji button
        IconButton(
          icon: const Icon(Icons.emoji_emotions_outlined),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Emoji picker coming soon!')),
            );
          },
          color: AppColors.primaryBlue,
        ),
        
        const Spacer(),
        
        // Character count
        if (_controller.text.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _remainingCharacters < 20
                  ? AppColors.warningColor.withOpacity(0.1)
                  : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _remainingCharacters.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: _remainingCharacters < 0
                    ? AppColors.errorColor
                    : _remainingCharacters < 20
                        ? AppColors.warningColor
                        : theme.brightness == Brightness.dark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}