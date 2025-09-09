import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tweet_model.dart';
import '../../providers/tweet_provider.dart';
import '../../constants/app_colors.dart';
import '../../screens/compose/compose_tweet_screen.dart';

class RetweetBottomSheet extends StatelessWidget {
  final TweetModel tweet;

  const RetweetBottomSheet({
    super.key,
    required this.tweet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Repost option
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.retweetColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.repeat,
                color: AppColors.retweetColor,
                size: 24,
              ),
            ),
            title: const Text(
              'Repost',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text('Instantly share to your timeline'),
            onTap: () => _handleRepost(context),
          ),
          
          const SizedBox(height: 8),
          
          // Quote option
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_outlined,
                color: AppColors.primaryBlue,
                size: 24,
              ),
            ),
            title: const Text(
              'Quote',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text('Add a comment, GIF, photo, etc.'),
            onTap: () => _handleQuote(context),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _handleRepost(BuildContext context) {
    Navigator.pop(context);
    
    // Toggle retweet
    context.read<TweetProvider>().toggleRetweetTweet(tweet.id);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.read<TweetProvider>().isRetweetedByCurrentUser(tweet.id)
              ? 'Retweeted!'
              : 'Retweet removed',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.retweetColor,
      ),
    );
  }

  void _handleQuote(BuildContext context) {
    Navigator.pop(context);
    
    // Navigate to compose screen with quote tweet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComposeTweetScreen(quoteTweet: tweet),
        fullscreenDialog: true,
      ),
    );
  }
}