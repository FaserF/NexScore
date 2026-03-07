import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

/// A reusable confetti celebration overlay widget.
///
/// Wrap your game screen body with this widget. Call [show] on the
/// [WinnerConfettiController] to trigger confetti (e.g., when a game
/// ends and a winner is determined).
///
/// Example usage:
/// ```dart
/// final _confettiController = WinnerConfettiController();
///
/// WinnerConfettiOverlay(
///   controller: _confettiController,
///   winnerName: 'Alice',
///   child: YourGameBody(),
/// )
///
/// // Later, when the game ends:
/// _confettiController.show();
/// ```
class WinnerConfettiController extends ChangeNotifier {
  bool _isShowing = false;
  String _winnerName = '';

  bool get isShowing => _isShowing;
  String get winnerName => _winnerName;

  void show({required String winnerName}) {
    _winnerName = winnerName;
    _isShowing = true;
    notifyListeners();
  }

  void hide() {
    _isShowing = false;
    notifyListeners();
  }
}

class WinnerConfettiOverlay extends StatefulWidget {
  final Widget child;
  final WinnerConfettiController controller;

  const WinnerConfettiOverlay({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  State<WinnerConfettiOverlay> createState() => _WinnerConfettiOverlayState();
}

class _WinnerConfettiOverlayState extends State<WinnerConfettiOverlay> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (widget.controller.isShowing) {
      _confettiController.play();
    } else {
      _confettiController.stop();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Center-top confetti burst
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 30,
            maxBlastForce: 40,
            minBlastForce: 10,
            emissionFrequency: 0.05,
            gravity: 0.15,
            colors: const [
              Colors.amber,
              Colors.pink,
              Colors.purple,
              Colors.cyan,
              Colors.green,
              Colors.orange,
            ],
            createParticlePath: (size) {
              // Star-shaped particles
              final path = Path();
              final halfWidth = size.width / 2;
              final halfHeight = size.height / 2;
              path.moveTo(halfWidth, 0);
              for (int i = 1; i < 5; i++) {
                final x = halfWidth + halfWidth * cos(i * 4 * pi / 5 - pi / 2);
                final y =
                    halfHeight + halfHeight * sin(i * 4 * pi / 5 - pi / 2);
                path.lineTo(x, y);
              }
              path.close();
              return path;
            },
          ),
        ),
        // Winner banner overlay
        if (widget.controller.isShowing)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: 0,
            right: 0,
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('👑', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 8),
                      Text(
                        widget.controller.winnerName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'WINNER!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Dismiss button
        if (widget.controller.isShowing)
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: FilledButton.icon(
                onPressed: () => widget.controller.hide(),
                icon: const Icon(Icons.replay),
                label: const Text('Continue'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
