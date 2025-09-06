import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bookmarks_provider.dart';
import '../../widgets/tweet/tweet_card.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookmarksProvider>().loadBookmarks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.bookmarks),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: AppColors.errorColor),
                    SizedBox(width: 8),
                    Text('Clear All', style: TextStyle(color: AppColors.errorColor)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'clear_all') {
                _showClearAllDialog();
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tweets'),
            Tab(text: 'Products'),
            Tab(text: 'Services'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTweetsTab(),
          _buildProductsTab(),
          _buildServicesTab(),
        ],
      ),
    );
  }

  Widget _buildTweetsTab() {
    return Consumer<BookmarksProvider>(
      builder: (context, bookmarksProvider, child) {
        if (bookmarksProvider.isLoading && bookmarksProvider.bookmarkedTweets.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookmarkedTweets = bookmarksProvider.bookmarkedTweets;

        if (bookmarkedTweets.isEmpty) {
          return _buildEmptyState(
            'No bookmarked tweets yet',
            'Tweets you bookmark will appear here.',
            Icons.bookmark_outline,
          );
        }

        return RefreshIndicator(
          onRefresh: () => bookmarksProvider.loadBookmarks(),
          child: ListView.builder(
            itemCount: bookmarkedTweets.length,
            itemBuilder: (context, index) {
              final tweet = bookmarkedTweets[index];
              return Column(
                children: [
                  TweetCard(tweet: tweet),
                  if (index < bookmarkedTweets.length - 1) const Divider(height: 1),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductsTab() {
    return Consumer<BookmarksProvider>(
      builder: (context, bookmarksProvider, child) {
        final bookmarkedProducts = bookmarksProvider.bookmarkedProducts;

        if (bookmarkedProducts.isEmpty) {
          return _buildEmptyState(
            'No bookmarked products yet',
            'Products you bookmark will appear here.',
            Icons.shopping_bag_outlined,
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: bookmarkedProducts.length,
          itemBuilder: (context, index) {
            final product = bookmarkedProducts[index];
            return Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildServicesTab() {
    return Consumer<BookmarksProvider>(
      builder: (context, bookmarksProvider, child) {
        final bookmarkedServices = bookmarksProvider.bookmarkedServices;

        if (bookmarkedServices.isEmpty) {
          return _buildEmptyState(
            'No bookmarked services yet',
            'Services you bookmark will appear here.',
            Icons.work_outline,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          itemCount: bookmarkedServices.length,
          itemBuilder: (context, index) {
            final service = bookmarkedServices[index];
            return Card(
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.work_outline,
                    color: Colors.grey,
                  ),
                ),
                title: Text(
                  service.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  service.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: service.startingPrice != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'From',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '\$${service.startingPrice!.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : null,
                onTap: () {
                  // Navigate to service detail
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
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

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Bookmarks'),
        content: const Text('Are you sure you want to remove all bookmarks? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<BookmarksProvider>().clearAllBookmarks();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All bookmarks cleared')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}