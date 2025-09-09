import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/tweet_model.dart';
import '../../providers/tweet_provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_colors.dart';
import '../../screens/tweet/tweet_detail_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/compose/compose_tweet_screen.dart';
import 'tweet_actions.dart';
import 'tweet_media.dart';

class TweetCard extends StatelessWidget {
  final TweetModel tweet;
  final bool showThread;
  final bool isDetail;
  final bool showActionButtons;

  const TweetCard({
    super.key,
    required this.tweet,
    this.showThread = false,
    this.isDetail = false,
    this.showActionButtons = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final currentUser = context.watch<AuthProvider>().currentUser;
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : AppColors.cardLight,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? AppColors.borderDark : AppColors.borderLight,
            width: 0.5,
          ),
        ),
      ),
      child: InkWell(
        onTap: isDetail
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TweetDetailScreen(tweet: tweet),
                  ),
                );
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Retweet indicator
              if (tweet.isRetweet) _buildRetweetIndicator(context),

              // Main tweet content
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile avatar
                  GestureDetector(
                    onTap: () {
                      if (tweet.user != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProfileScreen(userId: tweet.user!.id),
                          ),
                        );
                      }
                    },
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage: tweet.user?.profileImageUrl != null
                          ? NetworkImage(tweet.user!.profileImageUrl!)
                          : null,
                      child: tweet.user?.profileImageUrl == null
                          ? Text(
                              tweet.user?.displayName
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
                  ),
                  const SizedBox(width: 12),

                  // Tweet content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User info and timestamp
                        _buildUserInfo(context),
                        const SizedBox(height: 4),

                        // Tweet text
                        if (tweet.content.isNotEmpty) _buildTweetText(context),

                        // Media attachments
                        if (tweet.imageUrls.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: TweetMedia(imageUrls: tweet.imageUrls),
                          ),

                        // Quoted tweet
                        if (tweet.quotedTweet != null)
                          _buildQuotedTweet(context),

                        // Reply to tweet indicator
                        if (tweet.replyToTweet != null && !isDetail)
                          _buildReplyIndicator(context),

                        const SizedBox(height: 12),

                        // Tweet actions
                        if (showActionButtons)
                          TweetActions(
                            tweet: tweet,
                            onReply: () => _handleReply(context),
                            onRetweet: () => _handleRetweet(context),
                            onLike: () => _handleLike(context),
                            onShare: () => _handleShare(context),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRetweetIndicator(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 32, bottom: 4),
      child: Row(
        children: [
          Icon(Icons.repeat, size: 16, color: AppColors.retweetColor),
          const SizedBox(width: 4),
          Text(
            '${tweet.retweetedByUser?.displayName ?? 'Someone'} retweeted',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.retweetColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Display name
        GestureDetector(
          onTap: () {
            if (tweet.user != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(userId: tweet.user!.id),
                ),
              );
            }
          },
          child: Text(
            tweet.user?.displayName ?? 'Unknown User',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),

        // Verified badge
        if (tweet.user?.isVerified == true) ...[
          const SizedBox(width: 4),
          Icon(Icons.verified, size: 18, color: AppColors.verified),
        ],

        const SizedBox(width: 4),

        // Username and timestamp in same line
        Expanded(
          child: Text(
            '@${tweet.user?.username ?? 'unknown'} · ${timeago.format(tweet.createdAt, allowFromNow: true)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.brightness == Brightness.dark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontSize: 15,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // More options
        IconButton(
          icon: const Icon(Icons.more_horiz),
          iconSize: 20,
          onPressed: () => _showTweetOptions(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildTweetText(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        tweet.content,
        style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15, height: 1.4),
      ),
    );
  }

  Widget _buildQuotedTweet(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 8),
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
                backgroundImage:
                    tweet.quotedTweet!.user?.profileImageUrl != null
                    ? NetworkImage(tweet.quotedTweet!.user!.profileImageUrl!)
                    : null,
                child: tweet.quotedTweet!.user?.profileImageUrl == null
                    ? Text(
                        tweet.quotedTweet!.user?.displayName
                                .substring(0, 1)
                                .toUpperCase() ??
                            'U',
                        style: const TextStyle(fontSize: 10),
                      )
                    : null,
              ),
              const SizedBox(width: 6),
              Text(
                tweet.quotedTweet!.user?.displayName ?? 'Unknown',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '@${tweet.quotedTweet!.user?.username ?? 'unknown'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(tweet.quotedTweet!.content, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildReplyIndicator(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        'Replying to @${tweet.replyToUser?.username ?? 'unknown'}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }

  void _handleReply(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComposeTweetScreen(replyToTweet: tweet),
        fullscreenDialog: true,
      ),
    );
  }

  void _handleRetweet(BuildContext context) {
    context.read<TweetProvider>().toggleRetweetTweet(tweet.id);
  }

  void _handleLike(BuildContext context) {
    context.read<TweetProvider>().toggleLikeTweet(tweet.id);
  }

  void _handleShare(BuildContext context) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Share feature coming soon!')));
  }

  void _showTweetOptions(BuildContext context) {
    final currentUser = context.read<AuthProvider>().currentUser;
    final isOwnTweet = currentUser?.id == tweet.userId;

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOwnTweet) ...[
            ListTile(
              leading: const Icon(Icons.push_pin_outlined),
              title: Text(
                tweet.isPinned ? 'Unpin from profile' : 'Pin to profile',
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement pin/unpin functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pin feature coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.errorColor,
              ),
              title: const Text(
                'Delete Tweet',
                style: TextStyle(color: AppColors.errorColor),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement delete functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Delete feature coming soon!')),
                );
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.person_remove_outlined),
              title: Text('Unfollow @${tweet.user?.username ?? 'user'}'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement unfollow functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Unfollow feature coming soon!'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.block_outlined,
                color: AppColors.errorColor,
              ),
              title: Text(
                'Block @${tweet.user?.username ?? 'user'}',
                style: const TextStyle(color: AppColors.errorColor),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement block functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Block feature coming soon!')),
                );
              },
            ),
          ],
          ListTile(
            leading: const Icon(
              Icons.report_outlined,
              color: AppColors.errorColor,
            ),
            title: const Text(
              'Report Tweet',
              style: TextStyle(color: AppColors.errorColor),
            ),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement report functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report feature coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }
}
