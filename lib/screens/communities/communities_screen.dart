import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/community_model.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import 'create_community_screen.dart';
import 'community_detail_screen.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<CommunityModel> _filteredCommunities = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadCommunities();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterCommunities(String query) {
    final userProvider = context.read<UserProvider>();
    setState(() {
      _filteredCommunities = userProvider.searchCommunities(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.communities),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateCommunityScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Discover'),
            Tab(text: 'My Communities'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search communities',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterCommunities('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {});
                _filterCommunities(value);
              },
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildDiscoverTab(), _buildMyCommunitiesTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading && userProvider.communities.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (userProvider.error != null && userProvider.communities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  userProvider.error!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    userProvider.clearError();
                    userProvider.loadCommunities();
                  },
                  child: Text(AppStrings.retry),
                ),
              ],
            ),
          );
        }

        final communities = _searchController.text.isNotEmpty
            ? _filteredCommunities
            : userProvider.communities;

        if (communities.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => userProvider.loadCommunities(),
          child: ListView.builder(
            itemCount: communities.length,
            itemBuilder: (context, index) {
              final community = communities[index];
              return Column(
                children: [
                  CommunityTile(community: community),
                  if (index < communities.length - 1)
                    Divider(
                      height: 1,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMyCommunitiesTab() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        const currentUserId = 'user_1'; // This should come from AuthProvider

        final myCommunities = userProvider.communities
            .where((community) => community.members.contains(currentUserId))
            .toList();

        if (myCommunities.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => userProvider.loadCommunities(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 300,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 64,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No communities yet',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join or create communities to see them here.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateCommunityScreen(),
                            ),
                          );
                        },
                        child: Text(AppStrings.createCommunity),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => userProvider.loadCommunities(),
          child: ListView.builder(
            itemCount: myCommunities.length,
            itemBuilder: (context, index) {
              final community = myCommunities[index];
              return Column(
                children: [
                  CommunityTile(community: community, showJoinButton: false),
                  if (index < myCommunities.length - 1)
                    Divider(
                      height: 1,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups_outlined,
            size: 64,
            color: theme.brightness == Brightness.dark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 16),
          Text('No communities found', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Be the first to create a community!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.brightness == Brightness.dark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateCommunityScreen(),
                ),
              );
            },
            child: Text(AppStrings.createCommunity),
          ),
        ],
      ),
    );
  }
}

class CommunityTile extends StatelessWidget {
  final CommunityModel community;
  final bool showJoinButton;

  const CommunityTile({
    super.key,
    required this.community,
    this.showJoinButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    const currentUserId = 'user_1'; // This should come from AuthProvider
    final isMember = community.members.contains(currentUserId);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityDetailScreen(community: community),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            // Community avatar
            CircleAvatar(
              radius: 24,
              backgroundImage: community.profileImageUrl != null
                  ? NetworkImage(community.profileImageUrl!)
                  : null,
              child: community.profileImageUrl == null
                  ? Text(
                      community.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Community info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          community.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (community.isVerified) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified,
                          size: 16,
                          color: AppColors.verified,
                        ),
                      ],
                      if (community.isPrivate) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: theme.brightness == Brightness.dark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    community.description,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${community.membersCount} members • ${community.category}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.brightness == Brightness.dark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),

            // Join/Leave button
            if (showJoinButton) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  userProvider.joinCommunity(community.id, context);
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: isMember ? AppColors.primaryBlue : null,
                  foregroundColor: isMember
                      ? Colors.white
                      : AppColors.primaryBlue,
                  side: BorderSide(color: AppColors.primaryBlue),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  minimumSize: const Size(80, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isMember
                      ? AppStrings.leaveCommunity
                      : AppStrings.joinCommunity,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
