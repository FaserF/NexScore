import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/audio_provider.dart';
import '../../services/audio_service.dart';

class AnimatedScaleButton extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double scaleLowerBound;
  final Duration duration;

  const AnimatedScaleButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.scaleLowerBound = 0.95,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  ConsumerState<AnimatedScaleButton> createState() =>
      _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends ConsumerState<AnimatedScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      lowerBound: widget.scaleLowerBound,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.reverse();
    // Play click sound
    ref.read(audioServiceProvider).play(SfxType.click);
  }

  void _onTapUp(TapUpDetails details) {
    _controller.forward();
    widget.onPressed();
  }

  void _onTapCancel() {
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(scale: _controller, child: widget.child),
    );
  }
}
