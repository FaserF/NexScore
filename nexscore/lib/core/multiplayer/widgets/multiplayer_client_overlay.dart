import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/multiplayer_provider.dart';

/// Wraps any game screen to disable all touch interactions for multiplayer clients.
/// The host sees the screen normally. The client sees the screen with an IgnorePointer
/// overlay and a subtle banner at the top indicating they are spectating.
///
/// Usage: Wrap your game screen's body with this widget.
///   MultiplayerClientOverlay(child: _buildCardScreen(...))
class MultiplayerClientOverlay extends ConsumerWidget {
  final Widget child;

  /// Optional: allow specific widgets to remain interactive for clients
  /// (e.g. drink counter buttons). If provided, these are stacked on top.
  final Widget? clientInteractiveOverlay;

  const MultiplayerClientOverlay({
    super.key,
    required this.child,
    this.clientInteractiveOverlay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHost = ref.watch(isHostProvider);
    final lobby = ref.watch(currentLobbyProvider);

    // If not in a multiplayer session, just show the child directly
    if (lobby == null) return child;

    // Host sees everything normally
    if (isHost) return child;

    // Client: disable interactions but show the UI
    return Stack(
      children: [
        IgnorePointer(ignoring: true, child: child),
        // Spectating banner
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: Colors.amber.withValues(alpha: 0.9),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.visibility, size: 16, color: Colors.black87),
                SizedBox(width: 8),
                Text(
                  'Spectating — Host controls the game',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        // If client has interactive elements (e.g. drink counter), stack them on top
        if (clientInteractiveOverlay != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: clientInteractiveOverlay!,
          ),
      ],
    );
  }
}
