import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/community_model.dart';
import '../../providers/user_provider.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';

class CommunityDetailScreen extends StatefulWidget {
  final CommunityModel community;

  const CommunityDetailScreen({
    super.key,
    required this.community,
  });

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    const currentUserId = 'user_1'; // This should come from AuthProvider
    final isMember = widget.community.members.contains(currentUserId);
    final isModerator = widget.community.moderators.contains(currentUserId);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    image: widget.community.bannerImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(widget.community.bannerImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    gradient: widget.community.bannerImageUrl == null
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
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingLarge),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: widget.community.profileImageUrl != null
                                    ? NetworkImage(widget.community.profileImageUrl!)
                                    : null,
                                child: widget.community.profileImageUrl == null
                                    ? Text(
                                        widget.community.name.substring(0, 1).toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            widget.community.name,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (widget.community.isVerified) ...[
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.verified,
                                            color: AppColors.verified,
                                            size: 20,
                                          ),
                                        ],
                                        if (widget.community.isPrivate) ...[
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.lock,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      '${widget.community.membersCount} ${AppStrings.members}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
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
                ),
              ),
              actions: [
                PopupMenuButton(
                  itemBuilder: (context) => [
                    if (isModerator) ...[
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 8),
                            Text('Edit Community'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'manage',
                        child: Row(
                          children: [
                            Icon(Icons.settings_outlined),
                            SizedBox(width: 8),
                            Text('Manage'),
                          ],
                        ),
                      ),
                    ],
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined),
                          SizedBox(width: 8),
                          Text('Share'),
                        ],
                      ),
                    ),
                    if (!isMember)
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
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'share':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share feature coming soon!')),
                        );
                        break;
                      case 'edit':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Edit community feature coming soon!')),
                        );
                        break;
                      case 'manage':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Manage community feature coming soon!')),
                        );
                        break;
                      case 'report':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Report feature coming soon!')),
                        );
                        break;
                    }
                  },
                ),
              ],
            ),
          ];
        },
        body: Column(
          children: [
            // Community info and join button
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.community.description,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(widget.community.category),
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                        labelStyle: TextStyle(color: AppColors.primaryBlue),
                        side: BorderSide(color: AppColors.primaryBlue.withOpacity(0.3)),
                      ),
                      ...widget.community.tags.map((tag) => Chip(
                        label: Text('#$tag'),
                        backgroundColor: theme.brightness == Brightness.dark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight,
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        userProvider.joinCommunity(widget.community.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isMember ? AppColors.primaryBlue : AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        isMember ? AppStrings.leaveCommunity : AppStrings.joinCommunity,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
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
                tabs: const [
                  Tab(text: 'Posts'),
                  Tab(text: 'Members'),
                  Tab(text: 'About'),
                ],
              ),
            ),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPostsTab(),
                  _buildMembersTab(),
                  _buildAboutTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.post_add_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No posts yet'),
          SizedBox(height: 8),
          Text('Community posts will appear here'),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      children: [
        if (widget.community.creator != null) ...[
          ListTile(
            leading: CircleAvatar(
              backgroundImage: widget.community.creator!.profileImageUrl != null
                  ? NetworkImage(widget.community.creator!.profileImageUrl!)
                  : null,
              child: widget.community.creator!.profileImageUrl == null
                  ? Text(widget.community.creator!.displayName.substring(0, 1).toUpperCase())
                  : null,
            ),
            title: Text(widget.community.creator!.displayName),
            subtitle: Text('@${widget.community.creator!.username}'),
            trailing: const Chip(
              label: Text('Creator'),
              backgroundColor: AppColors.primaryBlue,
              labelStyle: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const Divider(),
        ],
        
        // Mock members (in real app, load from API)
        ...List.generate(5, (index) {
          return ListTile(
            leading: CircleAvatar(
              child: Text('U${index + 1}'),
            ),
            title: Text('User ${index + 1}'),
            subtitle: Text('@user${index + 1}'),
            trailing: widget.community.moderators.contains('user_${index + 1}')
                ? const Chip(
                    label: Text('Mod'),
                    backgroundColor: AppColors.retweetColor,
                    labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                  )
                : null,
          );
        }),
      ],
    );
  }

  Widget _buildAboutTab() {
    final theme = Theme.of(context);
    
    return ListView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Info',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.category_outlined, 'Category', widget.community.category),
                _buildInfoRow(Icons.people_outlined, 'Members', '${widget.community.membersCount}'),
                _buildInfoRow(Icons.calendar_today_outlined, 'Created', 
                    '${widget.community.createdAt.day}/${widget.community.createdAt.month}/${widget.community.createdAt.year}'),
                if (widget.community.isPrivate)
                  _buildInfoRow(Icons.lock_outlined, 'Privacy', 'Private Community'),
              ],
            ),
          ),
        ),
        
        if (widget.community.rules.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.communityRules,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.community.rules.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key + 1}. ',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.brightness == Brightness.dark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}