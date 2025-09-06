import 'package:flutter/material.dart';

class StoryProgressIndicator extends StatelessWidget {
  final int storiesCount;
  final int currentIndex;
  final AnimationController animationController;

  const StoryProgressIndicator({
    Key? key,
    required this.storiesCount,
    required this.currentIndex,
    required this.animationController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(storiesCount, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: index < storiesCount - 1 ? 4 : 0,
            ),
            child: _buildProgressBar(index),
          ),
        );
      }),
    );
  }

  Widget _buildProgressBar(int index) {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1.5),
        color: Colors.white.withOpacity(0.3),
      ),
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          double progress = 0.0;
          
          if (index < currentIndex) {
            progress = 1.0;
          } else if (index == currentIndex) {
            progress = animationController.value;
          }
          
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1.5),
              color: Colors.white,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1.5),
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}