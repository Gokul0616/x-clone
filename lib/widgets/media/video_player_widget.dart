import 'package:flutter/material.dart';
// Note: Add video_player package to pubspec.yaml
// For now, creating a placeholder widget

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool showControls;
  final double? aspectRatio;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.showControls = true,
    this.aspectRatio,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  bool _isPlaying = false;
  bool _showControls = true;
  double _currentPosition = 0.0;
  double _totalDuration = 100.0; // Placeholder

  @override
  void initState() {
    super.initState();
    _showControls = widget.showControls;
    _isPlaying = widget.autoPlay;
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    // Here you would implement actual video play/pause
  }

  void _toggleControls() {
    if (widget.showControls) {
      setState(() {
        _showControls = !_showControls;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio ?? 16 / 9,
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            // Video thumbnail/player area
            Center(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.video_library,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
            
            // Tap to toggle controls
            GestureDetector(
              onTap: _toggleControls,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),
            
            // Play/Pause button overlay
            if (_showControls)
              Center(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            
            // Bottom controls
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress bar
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white30,
                          thumbColor: Colors.white,
                          overlayColor: Colors.white.withOpacity(0.2),
                          trackHeight: 2,
                        ),
                        child: Slider(
                          value: _currentPosition,
                          max: _totalDuration,
                          onChanged: (value) {
                            setState(() {
                              _currentPosition = value;
                            });
                            // Here you would seek to the position
                          },
                        ),
                      ),
                      
                      // Control buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_10, color: Colors.white),
                            onPressed: () {
                              // Implement rewind 10 seconds
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: _togglePlayPause,
                          ),
                          IconButton(
                            icon: const Icon(Icons.forward_10, color: Colors.white),
                            onPressed: () {
                              // Implement forward 10 seconds
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.fullscreen, color: Colors.white),
                            onPressed: () {
                              // Implement fullscreen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullscreenVideoPlayer(
                                    videoUrl: widget.videoUrl,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FullscreenVideoPlayer extends StatelessWidget {
  final String videoUrl;

  const FullscreenVideoPlayer({
    super.key,
    required this.videoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: VideoPlayerWidget(
          videoUrl: videoUrl,
          autoPlay: true,
          aspectRatio: null,
        ),
      ),
    );
  }
}