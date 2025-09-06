import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tweet_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/tweet/tweet_card.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final userProvider = context.read<UserProvider>();
    final user = await userProvider.getUserById(widget.userId);
    
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = context.watch<AuthProvider>().currentUser;
    final userProvider = context.watch<UserProvider>();
    final isOwnProfile = currentUser?.id == widget.userId;
    final isFollowing = userProvider.isFollowingUser(widget.userId);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64),
              SizedBox(height: 16),
              Text('User not found'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Column(
                  children: [
                    // Banner
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        image: _user!.bannerImageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(_user!.bannerImageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        gradient: _user!.bannerImageUrl == null
                            ? LinearGradient(
                                colors: [
                                  AppColors.primaryBlue,
                                  AppColors.primaryBlueDark,
                                ],
                              )
                            : null,
                      ),
                    ),
                    
                    // Profile info
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.paddingMedium),
                        child: Column(
                          children: [
                            // Profile picture and action button
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Transform.translate(
                                  offset: const Offset(0, -40),
                                  child: CircleAvatar(
                                    radius: 40,
                                    backgroundColor: theme.scaffoldBackgroundColor,
                                    child: CircleAvatar(
                                      radius: 36,
                                      backgroundImage: _user!.profileImageUrl != null
                                          ? NetworkImage(_user!.profileImageUrl!)
                                          : null,
                                      child: _user!.profileImageUrl == null
                                          ? Text(
                                              _user!.displayName.substring(0, 1).toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (isOwnProfile)
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditProfileScreen(user: _user!),
                                        ),
                                      );
                                    },
                                    child: Text(AppStrings.editProfile),
                                  )
                                else
                                  OutlinedButton(
                                    onPressed: () {
                                      userProvider.followUser(widget.userId);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: isFollowing ? AppColors.primaryBlue : null,
                                      foregroundColor: isFollowing ? Colors.white : AppColors.primaryBlue,
                                    ),
                                    child: Text(isFollowing ? AppStrings.unfollow : AppStrings.follow),
                                  ),
                              ],
                            ),
                            
                            // User info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name and verification
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _user!.displayName,
                                          style: theme.textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (_user!.isVerified) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.verified,
                                          color: AppColors.verified,
                                          size: 20,
                                        ),
                                      ],
                                    ],
                                  ),
                                  
                                  // Username
                                  Text(
                                    '@${_user!.username}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.brightness == Brightness.dark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Bio
                                  if (_user!.bio != null && _user!.bio!.isNotEmpty)
                                    Text(
                                      _user!.bio!,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Location and website
                                  Wrap(
                                    spacing: 16,
                                    children: [
                                      if (_user!.location != null && _user!.location!.isNotEmpty)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.location_on_outlined,
                                              size: 16,
                                              color: theme.brightness == Brightness.dark
                                                  ? AppColors.textSecondaryDark
                                                  : AppColors.textSecondaryLight,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _user!.location!,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.brightness == Brightness.dark
                                                    ? AppColors.textSecondaryDark
                                                    : AppColors.textSecondaryLight,
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (_user!.website != null && _user!.website!.isNotEmpty)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.link,
                                              size: 16,
                                              color: AppColors.primaryBlue,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _user!.website!,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: AppColors.primaryBlue,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Join date
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 16,
                                        color: theme.brightness == Brightness.dark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${AppStrings.joined} ${_user!.joinedDate.month}/${_user!.joinedDate.year}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.brightness == Brightness.dark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // Follow stats
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Following list coming soon!')),
                                          );
                                        },
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: '${_user!.followingCount} ',
                                                style: theme.textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(
                                                text: AppStrings.following,
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.brightness == Brightness.dark
                                                      ? AppColors.textSecondaryDark
                                                      : AppColors.textSecondaryLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      GestureDetector(
                                        onTap: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Followers list coming soon!')),
                                          );
                                        },
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: '${_user!.followersCount} ',
                                                style: theme.textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(
                                                text: AppStrings.followers,
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.brightness == Brightness.dark
                                                      ? AppColors.textSecondaryDark
                                                      : AppColors.textSecondaryLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                PopupMenuButton(
                  itemBuilder: (context) => [
                    if (!isOwnProfile) ...[
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share_outlined),
                            SizedBox(width: 8),
                            Text('Share profile'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'block',
                        child: Row(
                          children: [
                            Icon(Icons.block_outlined, color: AppColors.errorColor),
                            SizedBox(width: 8),
                            Text('Block', style: TextStyle(color: AppColors.errorColor)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.report_outlined, color: AppColors.errorColor),
                            SizedBox(width: 8),
                            Text('Report', style: TextStyle(color: AppColors.errorColor)),
                          ],
                        ),
                      ),
                    ] else ...[
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share_outlined),
                            SizedBox(width: 8),
                            Text('Share profile'),
                          ],
                        ),
                      ),
                    ],
                  ],
                  onSelected: (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$value feature coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ];
        },
        body: Column(
          children: [
            // Tab bar
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.brightness == Brightness.dark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: AppStrings.tweets),
                  Tab(text: AppStrings.tweetsAndReplies),
                  Tab(text: AppStrings.media),
                  Tab(text: AppStrings.likes),
                ],
              ),
            ),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTweetsTab(),
                  _buildTweetsAndRepliesTab(),
                  _buildMediaTab(),
                  _buildLikesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTweetsTab() {
    return Consumer<TweetProvider>(
      builder: (context, tweetProvider, child) {
        final userTweets = tweetProvider.getTweetsByUser(widget.userId)
            .where((tweet) => tweet.replyToTweetId == null)
            .toList();

        if (userTweets.isEmpty) {
          return _buildEmptyState('No tweets yet', 'Tweets will appear here when posted.');
        }

        return ListView.builder(
          itemCount: userTweets.length,
          itemBuilder: (context, index) {
            final tweet = userTweets[index];
            return Column(
              children: [
                TweetCard(tweet: tweet),
                if (index < userTweets.length - 1) const Divider(height: 1),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTweetsAndRepliesTab() {
    return Consumer<TweetProvider>(
      builder: (context, tweetProvider, child) {
        final userTweets = tweetProvider.getTweetsByUser(widget.userId);

        if (userTweets.isEmpty) {
          return _buildEmptyState('No tweets yet', 'Tweets and replies will appear here.');
        }

        return ListView.builder(
          itemCount: userTweets.length,
          itemBuilder: (context, index) {
            final tweet = userTweets[index];
            return Column(
              children: [
                TweetCard(tweet: tweet, showThread: true),
                if (index < userTweets.length - 1) const Divider(height: 1),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMediaTab() {
    return Consumer<TweetProvider>(
      builder: (context, tweetProvider, child) {
        final userTweets = tweetProvider.getTweetsByUser(widget.userId)
            .where((tweet) => tweet.imageUrls.isNotEmpty)
            .toList();

        if (userTweets.isEmpty) {
          return _buildEmptyState('No media yet', 'Photos and videos will appear here.');
        }

        return ListView.builder(
          itemCount: userTweets.length,
          itemBuilder: (context, index) {
            final tweet = userTweets[index];
            return Column(
              children: [
                TweetCard(tweet: tweet),
                if (index < userTweets.length - 1) const Divider(height: 1),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLikesTab() {
    // In a real app, this would show tweets liked by the user
    return _buildEmptyState('No likes yet', 'Liked tweets will appear here.');
  }

  Widget _buildEmptyState(String title, String subtitle) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: theme.brightness == Brightness.dark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
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
}