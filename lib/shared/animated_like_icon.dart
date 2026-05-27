import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../core/app_assets.dart';
import '../core/constants.dart';

class AnimatedLikeIcon extends StatefulWidget {
  const AnimatedLikeIcon({
    super.key,
    required this.isLiked,
    this.size = 22,
    this.animate = true,
  });

  final bool isLiked;
  final double size;
  final bool animate;

  @override
  State<AnimatedLikeIcon> createState() => _AnimatedLikeIconState();
}

class _AnimatedLikeIconState extends State<AnimatedLikeIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  var _isPlaying = false;
  var _playWhenLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _isPlaying = false);
        }
      });
  }

  @override
  void didUpdateWidget(covariant AnimatedLikeIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isLiked && widget.isLiked && widget.animate) {
      setState(() => _isPlaying = true);
      if (_controller.duration == null) {
        _playWhenLoaded = true;
      } else {
        _controller.forward(from: 0);
      }
    } else if (oldWidget.isLiked && !widget.isLiked) {
      setState(() => _isPlaying = false);
      _playWhenLoaded = false;
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLiked && !_isPlaying) {
      return Icon(
        Icons.favorite_border_rounded,
        color: kMuted,
        size: widget.size,
      );
    }

    return SizedBox.square(
      dimension: widget.size + 10,
      child: Lottie.asset(
        AppAssets.likeButtonTappedAnimation,
        controller: _controller,
        fit: BoxFit.contain,
        repeat: false,
        onLoaded: (composition) {
          _controller.duration = composition.duration;
          if (_playWhenLoaded) {
            _playWhenLoaded = false;
            _controller.forward(from: 0);
          } else if (widget.isLiked && !_isPlaying) {
            _controller.value = 1;
          }
        },
      ),
    );
  }
}
