import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/audio_provider.dart';
import '../../core/services/audio_service.dart';
import '../../core/providers/share_provider.dart';
import 'shareable_scorecard.dart';

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
  String _gameName = '';
  List<PlayerScore> _scores = [];
  Color _winnerColor = Colors.amber;
  String? _winnerEmoji;

  bool get isShowing => _isShowing;
  String get winnerName => _winnerName;
  String get gameName => _gameName;
  List<PlayerScore> get scores => _scores;
  Color get winnerColor => _winnerColor;
  String? get winnerEmoji => _winnerEmoji;

  void show({
    required String winnerName,
    String gameName = '',
    List<PlayerScore> scores = const [],
    Color winnerColor = Colors.amber,
    String? winnerEmoji,
  }) {
    _winnerName = winnerName;
    _gameName = gameName;
    _scores = scores;
    _winnerColor = winnerColor;
    _winnerEmoji = winnerEmoji;
    _isShowing = true;
    notifyListeners();
  }

  void hide() {
    _isShowing = false;
    notifyListeners();
  }
}

class WinnerConfettiOverlay extends ConsumerStatefulWidget {
  final Widget child;
  final WinnerConfettiController controller;

  final bool showButtons;

  const WinnerConfettiOverlay({
    super.key,
    required this.child,
    required this.controller,
    this.showButtons = true,
  });

  @override
  ConsumerState<WinnerConfettiOverlay> createState() =>
      _WinnerConfettiOverlayState();
}

class _WinnerConfettiOverlayState extends ConsumerState<WinnerConfettiOverlay> {
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
      // Play fanfare sound
      ref.read(audioServiceProvider).play(SfxType.fanfare);
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
        // Action buttons
        if (widget.controller.isShowing && widget.showButtons)
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    ref
                        .read(shareServiceProvider)
                        .shareWidget(
                          context,
                          ShareableScorecard(
                            gameName: widget.controller.gameName,
                            winnerName: widget.controller.winnerName,
                            winnerEmoji: widget.controller.winnerEmoji,
                            winnerColor: widget.controller.winnerColor,
                            finalScores: widget.controller.scores,
                          ),
                          text:
                              'I just won ${widget.controller.gameName} on NexScore! 🏆',
                        );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share Results'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
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
              ],
            ),
          ),
      ],
    );
  }
}
