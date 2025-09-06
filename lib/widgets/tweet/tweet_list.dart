import 'package:flutter/material.dart';
import '../../models/tweet_model.dart';
import '../../constants/app_colors.dart';
import 'tweet_card.dart';

class TweetList extends StatefulWidget {
  final List<TweetModel> tweets;
  final VoidCallback? onLoadMore;
  final bool hasMoreTweets;
  final bool isLoadingMore;

  const TweetList({
    super.key,
    required this.tweets,
    this.onLoadMore,
    this.hasMoreTweets = false,
    this.isLoadingMore = false,
  });

  @override
  State<TweetList> createState() => _TweetListState();
}

class _TweetListState extends State<TweetList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (widget.hasMoreTweets && !widget.isLoadingMore && widget.onLoadMore != null) {
        widget.onLoadMore!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.tweets.length + (widget.hasMoreTweets ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.tweets.length) {
          // Loading indicator for pagination
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: widget.isLoadingMore
                  ? const CircularProgressIndicator()
                  : const SizedBox.shrink(),
            ),
          );
        }

        final tweet = widget.tweets[index];
        
        return Column(
          children: [
            TweetCard(tweet: tweet),
            if (index < widget.tweets.length - 1)
              Divider(
                height: 1,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
              ),
          ],
        );
      },
    );
  }
}