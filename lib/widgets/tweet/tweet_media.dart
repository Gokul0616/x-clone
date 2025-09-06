import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_constants.dart';

class TweetMedia extends StatelessWidget {
  final List<String> imageUrls;
  final double? height;

  const TweetMedia({
    super.key,
    required this.imageUrls,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    return Container(
      height: height ?? _getContainerHeight(),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: _buildMediaGrid(),
      ),
    );
  }

  double _getContainerHeight() {
    switch (imageUrls.length) {
      case 1:
        return 200;
      case 2:
        return 150;
      case 3:
      case 4:
        return 200;
      default:
        return 200;
    }
  }

  Widget _buildMediaGrid() {
    switch (imageUrls.length) {
      case 1:
        return _buildSingleImage();
      case 2:
        return _buildTwoImages();
      case 3:
        return _buildThreeImages();
      case 4:
        return _buildFourImages();
      default:
        return _buildSingleImage();
    }
  }

  Widget _buildSingleImage() {
    return _buildImageContainer(
      imageUrls[0],
      width: double.infinity,
      height: double.infinity,
    );
  }

  Widget _buildTwoImages() {
    return Row(
      children: [
        Expanded(
          child: _buildImageContainer(
            imageUrls[0],
            height: double.infinity,
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: _buildImageContainer(
            imageUrls[1],
            height: double.infinity,
          ),
        ),
      ],
    );
  }

  Widget _buildThreeImages() {
    return Row(
      children: [
        Expanded(
          child: _buildImageContainer(
            imageUrls[0],
            height: double.infinity,
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: _buildImageContainer(
                  imageUrls[1],
                  width: double.infinity,
                ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: _buildImageContainer(
                  imageUrls[2],
                  width: double.infinity,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFourImages() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildImageContainer(
                  imageUrls[0],
                  height: double.infinity,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _buildImageContainer(
                  imageUrls[1],
                  height: double.infinity,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildImageContainer(
                  imageUrls[2],
                  height: double.infinity,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _buildImageContainer(
                  imageUrls[3],
                  height: double.infinity,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageContainer(
    String imageUrl, {
    double? width,
    double? height,
  }) {
    return GestureDetector(
      onTap: () {
        // TODO: Implement full-screen image viewer
      },
      child: Container(
        width: width,
        height: height,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Icon(
              Icons.error_outline,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}