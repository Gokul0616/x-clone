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

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
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
    if (widget.userId.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final userProvider = context.read<UserProvider>();
    final authProvider = context.read<AuthProvider>();

    // If it's the current user's profile, use the current user data
    if (widget.userId == authProvider.currentUser?.id) {
      setState(() {
        _user = authProvider.currentUser;
        _isLoading = false;
      });
      return;
    }

    // Otherwise load from the API
    final user = await userProvider.getUserById(widget.userId);
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  Future<void> _handleRefresh() async {
    await _loadUser();
    // Also refresh tweets for this user
    await context.read<TweetProvider>().loadTweets(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = context.watch<AuthProvider>().currentUser;
    final userProvider = context.watch<UserProvider>();
    final isOwnProfile = currentUser?.id == widget.userId;
    final isFollowing = userProvider.isFollowingUser(widget.userId, context);

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
              expandedHeight: 410,
              pinned: true,
              stretch: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Banner
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        image: _user!.bannerImageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(_user!.bannerImageUrl!),
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) {
                                  // Handle image loading error
                                  print(
                                    'Error loading banner image: $exception',
                                  );
                                },
                              )
                            : null,
                        gradient: _user!.bannerImageUrl == null
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primaryBlue,
                                  AppColors.primaryBlueDark,
                                ],
                              )
                            : null,
                      ),
                    ),
                    // Profile content positioned overlay
                    Positioned(
                      top: 120,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(
                          AppConstants.paddingMedium,
                        ),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile picture and action button row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Transform.translate(
                                  offset: const Offset(0, -50),
                                  child: CircleAvatar(
                                    radius: 42,
                                    backgroundColor:
                                        theme.scaffoldBackgroundColor,
                                    child: CircleAvatar(
                                      radius: 38,
                                      backgroundImage:
                                          _user!.profileImageUrl != null
                                          ? NetworkImage(
                                              _user!.profileImageUrl!,
                                            )
                                          : null,
                                      child: _user!.profileImageUrl == null
                                          ? Text(
                                              _user!.displayName
                                                  .substring(0, 1)
                                                  .toUpperCase(),
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
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: isOwnProfile
                                      ? OutlinedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EditProfileScreen(
                                                      user: _user!,
                                                    ),
                                              ),
                                            );
                                          },
                                          child: Text(AppStrings.editProfile),
                                        )
                                      : OutlinedButton(
                                          onPressed: () {
                                            userProvider.followUser(
                                              widget.userId,
                                              context,
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: isFollowing
                                                ? AppColors.primaryBlue
                                                : null,
                                            foregroundColor: isFollowing
                                                ? Colors.white
                                                : AppColors.primaryBlue,
                                          ),
                                          child: Text(
                                            isFollowing
                                                ? AppStrings.unfollow
                                                : AppStrings.follow,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                            // User info
                            Transform.translate(
                              offset: const Offset(0, -30),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Name and verification
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _user!.displayName,
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
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
                                  const SizedBox(height: 4),
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
                                  if (_user!.bio != null &&
                                      _user!.bio!.isNotEmpty) ...[
                                    Text(
                                      _user!.bio!,
                                      style: theme.textTheme.bodyMedium,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  // Location and website
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 4,
                                    children: [
                                      if (_user!.location != null &&
                                          _user!.location!.isNotEmpty)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.location_on_outlined,
                                              size: 16,
                                              color:
                                                  theme.brightness ==
                                                      Brightness.dark
                                                  ? AppColors.textSecondaryDark
                                                  : AppColors
                                                        .textSecondaryLight,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                _user!.location!,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          theme.brightness ==
                                                              Brightness.dark
                                                          ? AppColors
                                                                .textSecondaryDark
                                                          : AppColors
                                                                .textSecondaryLight,
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (_user!.website != null &&
                                          _user!.website!.isNotEmpty)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.link,
                                              size: 16,
                                              color: AppColors.primaryBlue,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                _user!.website!,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      // Join date
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            size: 16,
                                            color:
                                                theme.brightness ==
                                                    Brightness.dark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${AppStrings.joined} ${_user!.joinedDate.month}/${_user!.joinedDate.year}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color:
                                                      theme.brightness ==
                                                          Brightness.dark
                                                      ? AppColors
                                                            .textSecondaryDark
                                                      : AppColors
                                                            .textSecondaryLight,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Follow stats
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Following list coming soon!',
                                              ),
                                            ),
                                          );
                                        },
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text:
                                                    '${_user!.followingCount} ',
                                                style: theme
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              TextSpan(
                                                text: AppStrings.following,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          theme.brightness ==
                                                              Brightness.dark
                                                          ? AppColors
                                                                .textSecondaryDark
                                                          : AppColors
                                                                .textSecondaryLight,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      GestureDetector(
                                        onTap: () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Followers list coming soon!',
                                              ),
                                            ),
                                          );
                                        },
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text:
                                                    '${_user!.followersCount} ',
                                                style: theme
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              TextSpan(
                                                text: AppStrings.followers,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          theme.brightness ==
                                                              Brightness.dark
                                                          ? AppColors
                                                                .textSecondaryDark
                                                          : AppColors
                                                                .textSecondaryLight,
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
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
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
                    isScrollable: false, // Changed to false for equal spacing
                    labelPadding: const EdgeInsets.symmetric(
                      horizontal: 0,
                    ), // Remove extra padding
                    tabs: const [
                      Tab(text: AppStrings.tweets),
                      Tab(text: AppStrings.tweetsAndReplies),
                      Tab(text: AppStrings.media),
                      Tab(text: AppStrings.likes),
                    ],
                  ),
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
                            Icon(
                              Icons.block_outlined,
                              color: AppColors.errorColor,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Block',
                              style: TextStyle(color: AppColors.errorColor),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(
                              Icons.report_outlined,
                              color: AppColors.errorColor,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Report',
                              style: TextStyle(color: AppColors.errorColor),
                            ),
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
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTweetsTab(),
            _buildTweetsAndRepliesTab(),
            _buildMediaTab(),
            _buildLikesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTweetsTab() {
    return Consumer<TweetProvider>(
      builder: (context, tweetProvider, child) {
        final userTweets = tweetProvider
            .getTweetsByUser(widget.userId)
            .where((tweet) => tweet.replyToTweetId == null)
            .toList();

        if (userTweets.isEmpty) {
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 300,
                child: _buildEmptyState(
                  'No tweets yet',
                  'Tweets will appear here when posted.',
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: ListView.builder(
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
          ),
        );
      },
    );
  }

  Widget _buildTweetsAndRepliesTab() {
    return Consumer<TweetProvider>(
      builder: (context, tweetProvider, child) {
        final userTweets = tweetProvider.getTweetsByUser(widget.userId);

        if (userTweets.isEmpty) {
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 300,
                child: _buildEmptyState(
                  'No tweets yet',
                  'Tweets and replies will appear here.',
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: ListView.builder(
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
          ),
        );
      },
    );
  }

  Widget _buildMediaTab() {
    return Consumer<TweetProvider>(
      builder: (context, tweetProvider, child) {
        final userTweets = tweetProvider
            .getTweetsByUser(widget.userId)
            .where((tweet) => tweet.imageUrls.isNotEmpty)
            .toList();

        if (userTweets.isEmpty) {
          return _buildEmptyState(
            'No media yet',
            'Photos and videos will appear here.',
          );
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
    return Consumer<TweetProvider>(
      builder: (context, tweetProvider, child) {
        final likedTweets = tweetProvider.tweets
            .where((tweet) => tweet.likedBy.contains(widget.userId))
            .toList();

        if (likedTweets.isEmpty) {
          return _buildEmptyState(
            'No likes yet',
            'Liked tweets will appear here.',
          );
        }

        return ListView.builder(
          itemCount: likedTweets.length,
          itemBuilder: (context, index) {
            final tweet = likedTweets[index];
            return Column(
              children: [
                TweetCard(tweet: tweet),
                if (index < likedTweets.length - 1) const Divider(height: 1),
              ],
            );
          },
        );
      },
    );
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
          Text(title, style: theme.textTheme.headlineSmall),
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
