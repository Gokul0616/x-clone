import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/story_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../screens/story/story_creator_screen.dart';
import '../story/story_ring.dart';
import '../story/story_viewer.dart';

class StoriesBar extends StatefulWidget {
  const StoriesBar({Key? key}) : super(key: key);

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoryProvider>().loadStories();
    });
  }

  void _openStoryCreator() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StoryCreatorScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  void _openStoryViewer(String userId, int userIndex) {
    final storyProvider = context.read<StoryProvider>();
    final userStories = storyProvider.getStoriesForUser(userId);
    
    if (userStories.isNotEmpty) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, _) => FadeTransition(
            opacity: animation,
            child: StoryViewer(
              stories: userStories,
              onStoryViewed: (storyId) {
                storyProvider.markStoryAsViewed(storyId);
              },
              onReaction: (storyId, emoji) {
                storyProvider.reactToStory(storyId, emoji);
              },
            ),
          ),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<StoryProvider, AuthProvider>(
      builder: (context, storyProvider, authProvider, child) {
        final currentUser = authProvider.currentUser;
        
        return Container(
          height: 100,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: storyProvider.usersWithStories.length + 1, // +1 for "Your story"
            itemBuilder: (context, index) {
              if (index == 0) {
                // Your story / Add story
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AnimatedStoryRing(
                    user: currentUser ?? _getDummyUser(),
                    isOwnStory: true,
                    showAddIcon: true,
                    onTap: _openStoryCreator,
                  ),
                );
              }

              final userIndex = index - 1;
              final user = storyProvider.usersWithStories[userIndex];
              final hasUnviewed = storyProvider.hasUnviewedStories(
                user.id,
                currentUser?.id,
              );

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: AnimatedStoryRing(
                  user: user,
                  hasUnviewedStories: hasUnviewed,
                  onTap: () => _openStoryViewer(user.id, userIndex),
                ),
              );
            },
          ),
        );
      },
    );
  }

  UserModel _getDummyUser() {
    return UserModel(
      id: 'current_user',
      username: 'you',
      displayName: 'You',
      email: 'user@example.com',
      joinedDate: DateTime.now(),
    );
  }
}

// Shimmer loading for stories bar
class StoriesBarShimmer extends StatefulWidget {
  const StoriesBarShimmer({Key? key}) : super(key: key);

  @override
  State<StoriesBarShimmer> createState() => _StoriesBarShimmerState();
}

class _StoriesBarShimmerState extends State<StoriesBarShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.grey.shade300,
                            Colors.grey.shade100,
                            Colors.grey.shade300,
                          ],
                          stops: [
                            (_animation.value - 1).clamp(0.0, 1.0),
                            _animation.value.clamp(0.0, 1.0),
                            (_animation.value + 1).clamp(0.0, 1.0),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Container(
                  width: 50,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}