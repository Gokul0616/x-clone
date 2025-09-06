import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../constants/app_colors.dart';

class StoryRing extends StatelessWidget {
  final UserModel user;
  final bool hasUnviewedStories;
  final bool isOwnStory;
  final VoidCallback? onTap;
  final double size;
  final bool showAddIcon;

  const StoryRing({
    Key? key,
    required this.user,
    this.hasUnviewedStories = false,
    this.isOwnStory = false,
    this.onTap,
    this.size = 70.0,
    this.showAddIcon = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasUnviewedStories
                  ? const LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Color(0xFFFF6B6B),
                        Color(0xFFFFE66D),
                        Color(0xFF4ECDC4),
                        Color(0xFF45B7D1),
                        Color(0xFF96CEB4),
                        Color(0xFFFDD835),
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        Colors.grey.shade300,
                        Colors.grey.shade400,
                      ],
                    ),
              padding: const EdgeInsets.all(3),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(size / 2),
                    child: user.profileImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: user.profileImageUrl!,
                            width: size - 6,
                            height: size - 6,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: size - 6,
                              height: size - 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade200,
                              ),
                              child: Icon(
                                Icons.person,
                                size: size * 0.4,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: size - 6,
                              height: size - 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade200,
                              ),
                              child: Icon(
                                Icons.person,
                                size: size * 0.4,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          )
                        : Container(
                            width: size - 6,
                            height: size - 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade200,
                            ),
                            child: Icon(
                              Icons.person,
                              size: size * 0.4,
                              color: Colors.grey.shade400,
                            ),
                          ),
                  ),
                  
                  // Add icon for own story
                  if (showAddIcon)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryBlue,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isOwnStory ? 'Your story' : user.username,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Animated story ring with shimmer effect
class AnimatedStoryRing extends StatefulWidget {
  final UserModel user;
  final bool hasUnviewedStories;
  final bool isOwnStory;
  final VoidCallback? onTap;
  final double size;
  final bool showAddIcon;

  const AnimatedStoryRing({
    Key? key,
    required this.user,
    this.hasUnviewedStories = false,
    this.isOwnStory = false,
    this.onTap,
    this.size = 70.0,
    this.showAddIcon = false,
  }) : super(key: key);

  @override
  State<AnimatedStoryRing> createState() => _AnimatedStoryRingState();
}

class _AnimatedStoryRingState extends State<AnimatedStoryRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.02,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: StoryRing(
                user: widget.user,
                hasUnviewedStories: widget.hasUnviewedStories,
                isOwnStory: widget.isOwnStory,
                size: widget.size,
                showAddIcon: widget.showAddIcon,
              ),
            ),
          );
        },
      ),
    );
  }
}