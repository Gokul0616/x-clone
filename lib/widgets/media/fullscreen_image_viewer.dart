import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FullscreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String? heroTag;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.heroTag,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showAppBar = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleAppBar() {
    setState(() {
      _showAppBar = !_showAppBar;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showAppBar
          ? AppBar(
              backgroundColor: Colors.black.withOpacity(0.7),
              elevation: 0,
              title: Text(
                '${_currentIndex + 1} of ${widget.imageUrls.length}',
                style: const TextStyle(color: Colors.white),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    // Implement share functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share feature coming soon!')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.white),
                  onPressed: () {
                    // Implement download functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Download feature coming soon!')),
                    );
                  },
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: _toggleAppBar,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemCount: widget.imageUrls.length,
          itemBuilder: (context, index) {
            return InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Hero(
                  tag: widget.heroTag ?? 'image_$index',
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrls[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 64,
                          ),
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
            );
          },
        ),
      ),
      bottomNavigationBar: _showAppBar && widget.imageUrls.length > 1
          ? Container(
              color: Colors.black.withOpacity(0.7),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}