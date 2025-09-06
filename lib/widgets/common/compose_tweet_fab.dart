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
      child: const Icon(
        Icons.add,
        color: Colors.white,
      ),
    );
  }
}