import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that wraps its child in a swipeable container.
/// Swiping left or right (or tapping) triggers [onSwipe].
/// The card animates out in the swipe direction and a new child
/// animates in from the opposite side when [cardKey] changes.
class SwipeableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onSwipe;
  final Key cardKey;

  const SwipeableCard({
    super.key,
    required this.child,
    required this.onSwipe,
    required this.cardKey,
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard> {
  double _dragOffset = 0;
  double _dragRotation = 0;
  bool _isDragging = false;

  static const double _swipeThreshold = 100.0;
  static const double _maxRotation = 0.15; // radians (~8.5 degrees)

  void _onHorizontalDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
      _dragRotation = (_dragOffset / 400).clamp(-_maxRotation, _maxRotation);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragOffset.abs() > _swipeThreshold) {
      HapticFeedback.mediumImpact();
      widget.onSwipe();
    }
    setState(() {
      _dragOffset = 0;
      _dragRotation = 0;
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onSwipe();
      },
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation);
          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Transform.translate(
          key: widget.cardKey,
          offset: Offset(_dragOffset, 0),
          child: Transform.rotate(
            angle: _dragRotation,
            child: Opacity(
              opacity: _isDragging
                  ? (1.0 - (_dragOffset.abs() / 400)).clamp(0.5, 1.0)
                  : 1.0,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
