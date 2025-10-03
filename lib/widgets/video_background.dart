import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBackground extends StatefulWidget {
  final Widget child;
  final String videoAsset;
  final double opacity;

  const VideoBackground({
    super.key,
    required this.child,
    required this.videoAsset,
    this.opacity = 0.2,
  });

  /// Background for auth screens
  factory VideoBackground.auth({required Widget child}) {
    return VideoBackground(
      videoAsset: 'assets/videos/signup.mp4',
      opacity: 0.1,
      child: child,
    );
  }

  /// Background for chat/home screens
  factory VideoBackground.chat({required Widget child}) {
    return VideoBackground(
      videoAsset: 'assets/videos/chat.mp4',
      opacity: 0.4,
      child: child,
    );
  }

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset(widget.videoAsset);
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.setVolume(0); // Muted
      await _controller.play();

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Video initialization failed: $e');
      // Fallback to particle background
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Video layer
        if (_isInitialized)
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),

        // Dark overlay for readability
        Positioned.fill(
          child: Container(
            color: Colors.black.withAlpha((widget.opacity * 255).round()),
          ),
        ),

        // Optional gradient overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withAlpha((67).round()),
                ],
              ),
            ),
          ),
        ),

        // Content
        widget.child,
      ],
    );
  }
}

/// Fallback: Static image background if video fails
class ImageBackground extends StatelessWidget {
  final Widget child;
  final String imageAsset;

  const ImageBackground({
    super.key,
    required this.child,
    required this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            imageAsset,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withAlpha((112).round()),
          ),
        ),
        child,
      ],
    );
  }
}
