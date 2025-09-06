import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tweet_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/tweet_model.dart';
import '../../models/user_model.dart';
import '../../widgets/tweet/tweet_card.dart';
import '../../widgets/common/user_tile.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  List<TweetModel> _searchResults = [];
  List<UserModel> _userResults = [];
  bool _isSearching = false;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _userResults = [];
        _currentQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _currentQuery = query;
    });

    final tweetProvider = context.read<TweetProvider>();
    final userProvider = context.read<UserProvider>();

    // Search tweets
    final tweets = tweetProvider.searchTweets(query);
    
    // Search users
    final users = await userProvider.searchUsers(query);

    setState(() {
      _searchResults = tweets;
      _userResults = users;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final tweetProvider = context.watch<TweetProvider>();
    
    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Pulse',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
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
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _performSearch(value);
                  }
                });
              },
            ),
          ),
          
          // Search content
          Expanded(
            child: _currentQuery.isEmpty
                ? _buildDefaultContent()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultContent() {
    final theme = Theme.of(context);
    final tweetProvider = context.watch<TweetProvider>();
    final trending = tweetProvider.getTrendingHashtags();
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trending section
          if (trending.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Text(
                'Trending',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...trending.take(10).map((hashtag) => ListTile(
              leading: const Icon(Icons.tag),
              title: Text('#$hashtag'),
              subtitle: const Text('Trending'),
              onTap: () {
                _searchController.text = '#$hashtag';
                _performSearch('#$hashtag');
              },
            )),
          ],
          
          // Recent searches (mock data)
          if (trending.isEmpty) _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty && _userResults.isEmpty) {
      return _buildNoResultsState();
    }

    return Column(
      children: [
        // Tab bar
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'All (${_searchResults.length + _userResults.length})'),
              Tab(text: 'Tweets (${_searchResults.length})'),
              Tab(text: 'People (${_userResults.length})'),
            ],
          ),
        ),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAllResults(),
              _buildTweetResults(),
              _buildUserResults(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllResults() {
    final allResults = <Widget>[];
    
    // Add users first (limited to 3)
    for (int i = 0; i < _userResults.length && i < 3; i++) {
      allResults.add(UserTile(user: _userResults[i]));
    }
    
    // Add tweets
    for (final tweet in _searchResults) {
      allResults.add(Column(
        children: [
          TweetCard(tweet: tweet),
          const Divider(height: 1),
        ],
      ));
    }
    
    if (allResults.isEmpty) {
      return _buildNoResultsState();
    }
    
    return ListView(
      children: allResults,
    );
  }

  Widget _buildTweetResults() {
    if (_searchResults.isEmpty) {
      return _buildNoResultsState(type: 'tweets');
    }
    
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final tweet = _searchResults[index];
        return Column(
          children: [
            TweetCard(tweet: tweet),
            if (index < _searchResults.length - 1) const Divider(height: 1),
          ],
        );
      },
    );
  }

  Widget _buildUserResults() {
    if (_userResults.isEmpty) {
      return _buildNoResultsState(type: 'people');
    }
    
    return ListView.builder(
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        return UserTile(user: user);
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
            Icons.search,
            size: 64,
            color: theme.brightness == Brightness.dark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Search for people and tweets',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Find what\'s happening and discover new voices on Pulse.',
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

  Widget _buildNoResultsState({String? type}) {
    final theme = Theme.of(context);
    final searchType = type ?? 'results';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.brightness == Brightness.dark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No $searchType found',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for something else.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.brightness == Brightness.dark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}