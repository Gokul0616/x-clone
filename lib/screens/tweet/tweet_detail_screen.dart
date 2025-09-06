import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tweet_model.dart';
import '../../providers/tweet_provider.dart';
import '../../widgets/tweet/tweet_card.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../compose/compose_tweet_screen.dart';

class TweetDetailScreen extends StatefulWidget {
  final TweetModel tweet;

  const TweetDetailScreen({
    super.key,
    required this.tweet,
  });

  @override
  State<TweetDetailScreen> createState() => _TweetDetailScreenState();
}

class _TweetDetailScreenState extends State<TweetDetailScreen> {
  List<TweetModel> _replies = [];
  bool _isLoadingReplies = false;

  @override
  void initState() {
    super.initState();
    _loadReplies();
  }

  Future<void> _loadReplies() async {
    setState(() {
      _isLoadingReplies = true;
    });

    final tweetProvider = context.read<TweetProvider>();
    final replies = await tweetProvider.getTweetReplies(widget.tweet.id);
    
    setState(() {
      _replies = replies;
      _isLoadingReplies = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tweet'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // Main tweet
                TweetCard(
                  tweet: widget.tweet,
                  isDetail: true,
                ),
                
                // Divider
                Container(
                  height: 8,
                  color: theme.brightness == Brightness.dark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                ),
                
                // Replies section
                if (_isLoadingReplies)
                  const Padding(
                    padding: EdgeInsets.all(AppConstants.paddingLarge),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_replies.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: theme.brightness == Brightness.dark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No replies yet',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to reply!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.brightness == Brightness.dark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Replies list
                  ...(_replies.map((reply) => Column(
                    children: [
                      TweetCard(tweet: reply),
                      Divider(
                        height: 1,
                        color: theme.brightness == Brightness.dark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ],
                  ))),
              ],
            ),
          ),
          
          // Reply input
          _buildReplyInput(),
        ],
      ),
    );
  }

  Widget _buildReplyInput() {
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Reply to @${widget.tweet.user?.username ?? 'user'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ComposeTweetScreen(replyToTweet: widget.tweet),
                  fullscreenDialog: true,
                ),
              );
            },
            backgroundColor: AppColors.primaryBlue,
            child: const Icon(Icons.reply, color: Colors.white),
          ),
        ],
      ),
    );
  }
}