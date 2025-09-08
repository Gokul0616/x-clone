import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/tweet_provider.dart';
import '../../widgets/tweet/tweet_list.dart';
import '../../widgets/common/custom_reload_animation.dart';
import '../../constants/app_colors.dart';

class FullscreenFeedScreen extends StatefulWidget {
  const FullscreenFeedScreen({super.key});

  @override
  State<FullscreenFeedScreen> createState() => _FullscreenFeedScreenState();
}

class _FullscreenFeedScreenState extends State<FullscreenFeedScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _showControls = true;
  bool _isImmersiveMode = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1)).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );

    // Auto-hide controls after 3 seconds
    _startAutoHideTimer();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _startAutoHideTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        _toggleControls();
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _fadeController.reverse();
      _slideController.reverse();
      _startAutoHideTimer();
    } else {
      _fadeController.forward();
      _slideController.forward();
    }
  }

  void _toggleImmersiveMode() {
    setState(() {
      _isImmersiveMode = !_isImmersiveMode;
    });

    if (_isImmersiveMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Future<void> _handleRefresh() async {
    await context.read<TweetProvider>().refreshTweets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Main content
          GestureDetector(
            onTap: _toggleControls,
            child: Consumer<TweetProvider>(
              builder: (context, tweetProvider, child) {
                if (tweetProvider.isLoading && tweetProvider.tweets.isEmpty) {
                  return const Center(
                    child: CustomReloadAnimation(size: 60, isAnimating: true),
                  );
                }

                if (tweetProvider.error != null &&
                    tweetProvider.tweets.isEmpty) {
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
                          child: const Text('Retry'),
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
                    showActionButtons:
                        false, // Hide action buttons for distraction-free reading
                  ),
                );
              },
            ),
          ),

          // Top controls
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: 1.0 - _fadeAnimation.value,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    height: MediaQuery.of(context).padding.top + 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).scaffoldBackgroundColor,
                          Theme.of(
                            context,
                          ).scaffoldBackgroundColor.withOpacity(0.9),
                          Theme.of(
                            context,
                          ).scaffoldBackgroundColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () {
                              SystemChrome.setEnabledSystemUIMode(
                                SystemUiMode.edgeToEdge,
                              );
                              Navigator.of(context).pop();
                            },
                          ),
                          Expanded(
                            child: Text(
                              'Fullscreen Feed',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isImmersiveMode
                                  ? Icons.fullscreen_exit
                                  : Icons.fullscreen,
                            ),
                            onPressed: _toggleImmersiveMode,
                            tooltip: _isImmersiveMode
                                ? 'Exit immersive mode'
                                : 'Enter immersive mode',
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: () {
                              _showFeedSettings();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Bottom controls
          if (_showControls)
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: 1.0 - _fadeAnimation.value,
                  child: Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80 + MediaQuery.of(context).padding.bottom,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Theme.of(context).scaffoldBackgroundColor,
                            Theme.of(
                              context,
                            ).scaffoldBackgroundColor.withOpacity(0.9),
                            Theme.of(
                              context,
                            ).scaffoldBackgroundColor.withOpacity(0.0),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildControlButton(
                              Icons.home,
                              'Home',
                              () => Navigator.of(context).pop(),
                            ),
                            _buildControlButton(
                              Icons.refresh,
                              'Refresh',
                              _handleRefresh,
                            ),
                            _buildControlButton(
                              Icons.settings,
                              'Settings',
                              _showFeedSettings,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  void _showFeedSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feed Settings',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  ListTile(
                    leading: Icon(
                      _isImmersiveMode
                          ? Icons.fullscreen_exit
                          : Icons.fullscreen,
                    ),
                    title: Text(
                      _isImmersiveMode
                          ? 'Exit Immersive Mode'
                          : 'Enter Immersive Mode',
                    ),
                    subtitle: const Text(
                      'Hide system UI for distraction-free reading',
                    ),
                    onTap: () {
                      _toggleImmersiveMode();
                      Navigator.pop(context);
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text('Refresh Feed'),
                    subtitle: const Text('Load latest tweets'),
                    onTap: () {
                      Navigator.pop(context);
                      _handleRefresh();
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.visibility_off),
                    title: Text(
                      _showControls ? 'Hide Controls' : 'Show Controls',
                    ),
                    subtitle: const Text(
                      'Toggle visibility of control buttons',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _toggleControls();
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
