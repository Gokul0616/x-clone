import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tweet_model.dart';
import '../../providers/tweet_provider.dart';
import '../../constants/app_colors.dart';

class TweetActions extends StatelessWidget {
  final TweetModel tweet;
  final VoidCallback? onReply;
  final VoidCallback? onRetweet;
  final VoidCallback? onLike;
  final VoidCallback? onShare;

  const TweetActions({
    super.key,
    required this.tweet,
    this.onReply,
    this.onRetweet,
    this.onLike,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final tweetProvider = context.watch<TweetProvider>();
    final isLiked = tweetProvider.isLikedByCurrentUser(tweet.id);
    final isRetweeted = tweetProvider.isRetweetedByCurrentUser(tweet.id);
    
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Reply
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            count: tweet.repliesCount,
            color: AppColors.replyColor,
            onPressed: onReply,
          ),
          
          // Retweet
          _buildActionButton(
            icon: Icons.repeat,
            count: tweet.retweetsCount,
            color: isRetweeted ? AppColors.retweetColor : AppColors.replyColor,
            isActive: isRetweeted,
            onPressed: onRetweet,
          ),
          
          // Like
          _buildActionButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            count: tweet.likesCount,
            color: isLiked ? AppColors.likeColor : AppColors.replyColor,
            isActive: isLiked,
            onPressed: onLike,
          ),
          
          // Share
          _buildActionButton(
            icon: Icons.share_outlined,
            color: AppColors.replyColor,
            onPressed: onShare,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    int? count,
    required Color color,
    bool isActive = false,
    VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? color : color.withOpacity(0.6),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 4),
              Text(
                _formatCount(count),
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? color : color.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}