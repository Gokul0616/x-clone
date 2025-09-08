import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_constants.dart';

class TweetMedia extends StatelessWidget {
  final List<String> imageUrls;
  final double? height;

  const TweetMedia({super.key, required this.imageUrls, this.height});

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
        child: _buildMediaGrid(context),
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

  Widget _buildMediaGrid(BuildContext context) {
    switch (imageUrls.length) {
      case 1:
        return _buildSingleImage(context);
      case 2:
        return _buildTwoImages(context);
      case 3:
        return _buildThreeImages(context);
      case 4:
        return _buildFourImages(context);
      default:
        return _buildSingleImage(context);
    }
  }

  Widget _buildSingleImage(BuildContext context) {
    return _buildImageContainer(
      context,
      imageUrls[0],
      width: double.infinity,
      height: double.infinity,
    );
  }

  Widget _buildTwoImages(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildImageContainer(
            context,
            imageUrls[0],
            height: double.infinity,
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: _buildImageContainer(
            context,
            imageUrls[1],
            height: double.infinity,
          ),
        ),
      ],
    );
  }

  Widget _buildThreeImages(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildImageContainer(
            context,
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
                  context,
                  imageUrls[1],
                  width: double.infinity,
                ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: _buildImageContainer(
                  context,
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

  Widget _buildFourImages(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildImageContainer(
                  context,
                  imageUrls[0],
                  height: double.infinity,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _buildImageContainer(
                  context,
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
                  context,
                  imageUrls[2],
                  height: double.infinity,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _buildImageContainer(
                  context,
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
    BuildContext context,
    String imageUrl, {
    double? width,
    double? height,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, _) => FadeTransition(
              opacity: animation,
              child: _buildFullscreenImageViewer(context, imageUrl),
            ),
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            opaque: false,
          ),
        );
      },
      child: SizedBox(
        width: width,
        height: height,
        child: Hero(
          tag: 'image_$imageUrl',
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
              child: const Icon(Icons.error_outline, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullscreenImageViewer(BuildContext context, String imageUrl) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download feature coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: InteractiveViewer(
        panEnabled: true,
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Hero(
            tag: 'image_$imageUrl',
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
