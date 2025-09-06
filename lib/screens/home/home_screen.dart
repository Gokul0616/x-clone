import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tweet_provider.dart';
import '../../widgets/tweet/tweet_list.dart';
import '../../widgets/story/stories_bar.dart';
import '../../widgets/common/custom_reload_animation.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // Load tweets when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TweetProvider>().loadTweets();
    });
  }

  Future<void> _handleRefresh() async {
    await context.read<TweetProvider>().refreshTweets();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      body: Consumer<TweetProvider>(
        builder: (context, tweetProvider, child) {
          if (tweetProvider.isLoading && tweetProvider.tweets.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (tweetProvider.error != null && tweetProvider.tweets.isEmpty) {
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
                    tweetProvider.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      tweetProvider.clearError();
                      tweetProvider.loadTweets(refresh: true);
                    },
                    child: Text(AppStrings.retry),
                  ),
                ],
              ),
            );
          }

          if (tweetProvider.tweets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.electric_bolt_outlined,
                    size: 64,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to ${AppStrings.appName}!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your timeline will appear here when you follow people or join communities.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: TweetList(
              tweets: tweetProvider.tweets,
              onLoadMore: tweetProvider.loadMoreTweets,
              hasMoreTweets: tweetProvider.hasMoreTweets,
              isLoadingMore: tweetProvider.isLoadingMore,
            ),
          );
        },
      ),
    );
  }
}