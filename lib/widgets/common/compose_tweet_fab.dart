import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../screens/compose/compose_tweet_screen.dart';

class ComposeTweetFAB extends StatelessWidget {
  const ComposeTweetFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ComposeTweetScreen(),
            fullscreenDialog: true,
          ),
        );
      },
      backgroundColor: AppColors.primaryBlue,
      elevation: 4,
      child: const Icon(
        Icons.edit,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}