import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedLogoWidget extends StatefulWidget {
  final List<String> frameAssetPaths;
  final Duration frameDuration;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AnimatedLogoWidget({
    super.key,
    required this.frameAssetPaths,
    this.frameDuration = const Duration(milliseconds: 300), // Duration each frame is shown
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  })  : assert(frameAssetPaths.length > 0, 'frameAssetPaths cannot be empty');

  @override
  _AnimatedLogoWidgetState createState() => _AnimatedLogoWidgetState();
}

class _AnimatedLogoWidgetState extends State<AnimatedLogoWidget> {
  int _currentFrameIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.frameAssetPaths.length > 1) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _timer = Timer.periodic(widget.frameDuration, (timer) {
      if (mounted) { // Check if the widget is still in the tree
        setState(() {
          _currentFrameIndex = (_currentFrameIndex + 1) % widget.frameAssetPaths.length;
        });
      } else {
        timer.cancel(); // Cancel timer if widget is disposed
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.frameAssetPaths.isEmpty) {
      return SizedBox(width: widget.width, height: widget.height); // Or some placeholder
    }

    return Image.asset(
      widget.frameAssetPaths[_currentFrameIndex],
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true, // Helps prevent flickering between frames
    );
  }
}