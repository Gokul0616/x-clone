import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../models/story_model.dart';
import '../../constants/app_colors.dart';
import 'story_progress_indicator.dart';
import 'story_reactions.dart';

class StoryViewer extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;
  final VoidCallback? onClose;
  final Function(String storyId)? onStoryViewed;
  final Function(String storyId, String emoji)? onReaction;

  const StoryViewer({
    Key? key,
    required this.stories,
    this.initialIndex = 0,
    this.onClose,
    this.onStoryViewed,
    this.onReaction,
  }) : super(key: key);

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  late AnimationController _reactionController;
  VideoPlayerController? _videoController;
  
  int _currentIndex = 0;
  bool _isPaused = false;
  bool _showReactions = false;
  static const Duration _storyDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    
    _progressController = AnimationController(
      duration: _storyDuration,
      vsync: this,
    );
    
    _reactionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _startStoryTimer();
    _markStoryAsViewed();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _reactionController.dispose();
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _startStoryTimer() {
    _progressController.reset();
    
    if (widget.stories[_currentIndex].type == StoryType.video) {
      _initVideoPlayer();
    } else {
      _progressController.forward().then((_) {
        if (!_isPaused) {
          _nextStory();
        }
      });
    }
  }

  void _initVideoPlayer() async {
    final story = widget.stories[_currentIndex];
    if (story.mediaUrl != null) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.network(story.mediaUrl!);
      
      try {
        await _videoController!.initialize();
        _videoController!.play();
        
        // Use video duration for progress
        final videoDuration = _videoController!.value.duration;
        _progressController.duration = videoDuration.inMilliseconds == 0 
            ? _storyDuration 
            : videoDuration;
        
        _progressController.forward().then((_) {
          if (!_isPaused) {
            _nextStory();
          }
        });
        
        setState(() {});
      } catch (e) {
        print('Error initializing video: $e');
        // Fallback to default duration
        _progressController.forward().then((_) {
          if (!_isPaused) {
            _nextStory();
          }
        });
      }
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      _currentIndex++;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStoryTimer();
      _markStoryAsViewed();
    } else {
      _closeViewer();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStoryTimer();
      _markStoryAsViewed();
    }
  }

  void _pauseStory() {
    setState(() {
      _isPaused = true;
    });
    _progressController.stop();
    _videoController?.pause();
  }

  void _resumeStory() {
    setState(() {
      _isPaused = false;
    });
    _progressController.forward();
    _videoController?.play();
  }

  void _markStoryAsViewed() {
    final story = widget.stories[_currentIndex];
    widget.onStoryViewed?.call(story.id);
  }

  void _closeViewer() {
    Navigator.of(context).pop();
    widget.onClose?.call();
  }

  void _showReactionPicker() {
    setState(() {
      _showReactions = true;
    });
    _reactionController.forward();
    _pauseStory();
  }

  void _hideReactionPicker() {
    _reactionController.reverse().then((_) {
      setState(() {
        _showReactions = false;
      });
    });
    _resumeStory();
  }

  void _reactToStory(String emoji) {
    
    final story = widget.stories[_currentIndex];
    widget.onReaction?.call(story.id, emoji);
    
    _hideReactionPicker();
    
    // Show brief reaction feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reacted with $emoji'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Story content
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              _currentIndex = index;
              _startStoryTimer();
              _markStoryAsViewed();
            },
            itemCount: widget.stories.length,
            itemBuilder: (context, index) {
              return _buildStoryContent(widget.stories[index]);
            },
          ),

          // Progress indicators
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: StoryProgressIndicator(
              storiesCount: widget.stories.length,
              currentIndex: _currentIndex,
              animationController: _progressController,
            ),
          ),

          // Story header
          Positioned(
            top: MediaQuery.of(context).padding.top + 40,
            left: 16,
            right: 16,
            child: _buildStoryHeader(),
          ),

          // Tap areas for navigation
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _previousStory,
                  onLongPressStart: (_) => _pauseStory(),
                  onLongPressEnd: (_) => _resumeStory(),
                  child: Container(
                    height: double.infinity,
                    color: Colors.transparent,
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _nextStory,
                  onLongPressStart: (_) => _pauseStory(),
                  onLongPressEnd: (_) => _resumeStory(),
                  child: Container(
                    height: double.infinity,
                    color: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),

          // Story actions
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 16,
            right: 16,
            child: _buildStoryActions(),
          ),

          // Reaction picker overlay
          if (_showReactions)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _reactionController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _reactionController.value,
                        child: StoryReactions(
                          onReaction: _reactToStory,
                          onClose: _hideReactionPicker,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoryContent(StoryModel story) {
    switch (story.type) {
      case StoryType.image:
        return _buildImageStory(story);
      case StoryType.video:
        return _buildVideoStory(story);
      case StoryType.text:
        return _buildTextStory(story);
    }
  }

  Widget _buildImageStory(StoryModel story) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: story.mediaUrl != null
          ? CachedNetworkImage(
              imageUrl: story.mediaUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade900,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade900,
                child: const Center(
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            )
          : Container(
              color: Colors.grey.shade900,
              child: const Center(
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ),
    );
  }

  Widget _buildVideoStory(StoryModel story) {
    if (_videoController != null && _videoController!.value.isInitialized) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoController!.value.size.width,
            height: _videoController!.value.size.height,
            child: VideoPlayer(_videoController!),
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey.shade900,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildTextStory(StoryModel story) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: story.backgroundColor != null
            ? Color(int.parse(story.backgroundColor!.replaceFirst('#', '0xFF')))
            : AppColors.primaryBlue,
        gradient: story.backgroundColor != null
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667eea),
                  Color(0xFF764ba2),
                ],
              ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            story.textContent ?? '',
            style: TextStyle(
              color: story.textColor != null
                  ? Color(int.parse(story.textColor!.replaceFirst('#', '0xFF')))
                  : Colors.white,
              fontSize: story.fontSize ?? 28,
              fontWeight: FontWeight.bold,
              fontFamily: story.fontFamily,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildStoryHeader() {
    final story = widget.stories[_currentIndex];
    final user = story.user;

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: user?.profileImageUrl != null
              ? CachedNetworkImageProvider(user!.profileImageUrl!)
              : null,
          child: user?.profileImageUrl == null
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.displayName ?? user?.username ?? 'Unknown',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatStoryTime(story.createdAt),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _closeViewer,
          icon: const Icon(
            Icons.close,
            color: Colors.white,
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildStoryActions() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Send message',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Colors.white),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _showReactionPicker,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white24,
            ),
            child: const Icon(
              Icons.favorite_border,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            // Implement share functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Share functionality coming soon!'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white24,
            ),
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  String _formatStoryTime(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}