import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Game Feature Parity Integrity Tests', () {
    final gamesDir = Directory('lib/features/games');
    final List<File> screenFiles = [];

    if (gamesDir.existsSync()) {
      final entities = gamesDir.listSync(recursive: true);
      for (final entity in entities) {
        if (entity is File &&
            (entity.path.endsWith('_screen.dart') ||
                entity.path.endsWith('_scoreboard.dart'))) {
          // Exclude non-game screens
          if (!entity.path.contains('games_list_screen.dart') &&
              !entity.path.contains('game_setup_screen.dart') &&
              !entity.path.contains('generic_scoreboard_setup.dart')) {
            // ignoring any generic non-main screens if present
            screenFiles.add(entity);
          }
        }
      }
    }

    for (final file in screenFiles) {
      // Extract game name from filename
      final fileName = file.path.split(RegExp(r'[\\/]')).last;
      final gameName = fileName
          .replaceAll('_screen.dart', '')
          .replaceAll('_scoreboard.dart', '');

      test('Game $gameName should maintain feature parity', () {
        _checkFileForParity(file, gameName);
      });
    }
  });
}

void _checkFileForParity(File file, String gameName) {
  final content = file.readAsStringSync();

  // 1. Early Finish / Manual Finish
  expect(
    content.contains('Icons.check_circle_outline') ||
        content.contains('finishGame') ||
        content.contains('endGame') ||
        content.contains('onFinish') ||
        content.contains('Icons.done_all'),
    isTrue,
    reason: 'Game $gameName is missing an Early Finish button or logic.',
  );

  // 2. Winner Celebration (Confetti & Sound)
  expect(
    content.contains('WinnerConfettiController') ||
        content.contains('WinnerOverlay') ||
        content.contains('WinnerDialog') ||
        content.contains('WinnerScreen') ||
        content.contains('confetti') ||
        content.contains('showWinner'),
    isTrue,
    reason: 'Game $gameName is missing winner celebration (Confetti/Overlay).',
  );

  // Checking for audio service or fanfare sound usage for winner
  expect(
    content.contains('AudioService') ||
        content.contains('SfxType.fanfare') ||
        content.contains('play(SfxType.fanfare)') ||
        content.contains('winnerSound') ||
        content.contains('playSound'),
    isTrue,
    reason: 'Game $gameName is missing winner sound (e.g. SfxType.fanfare).',
  );

  // 3. Multiplayer Support
  expect(
    content.contains('MultiplayerClientOverlay') ||
        content.contains('Multiplayer') ||
        content.contains('ref.watch(multiplayer') ||
        content.contains('multiplayer_provider'),
    isTrue,
    reason:
        'Game $gameName is missing MultiplayerClientOverlay or multiplayer integration.',
  );

  // 4. Reset Game
  expect(
    (content.contains('Icons.refresh') ||
            content.contains('Icons.restart_alt')) &&
        (content.contains('reset') || content.contains('restart')),
    isTrue,
    reason: 'Game $gameName is missing a Game Reset button (Icons.refresh).',
  );

  // 5. Undo Action
  expect(
    (content.contains('Icons.undo') || content.contains('Icons.history')) &&
        (content.contains('undo') || content.contains('revert')),
    isTrue,
    reason: 'Game $gameName is missing an Undo button (Icons.undo).',
  );

  // 6. Configurable Settings
  expect(
    content.contains('Icons.settings') ||
        content.contains('Icons.edit_note') ||
        content.contains('Icons.tune'),
    isTrue,
    reason: 'Game $gameName is missing a Settings/Configuration button.',
  );

  // 7. Help Documentation
  expect(
    content.contains('Icons.help_outline') || content.contains('Icons.help'),
    isTrue,
    reason: 'Game $gameName is missing a Help button (Icons.help_outline).',
  );

  // 8. Game Persistence (Continue Mode)
  expect(
    content.contains('setupDone') ||
        content.contains('fromJson') ||
        content.contains('toJson') ||
        content.contains('isFinished') ||
        content.contains('gameState') ||
        content.contains('Persistence'),
    isTrue,
    reason:
        'Game $gameName is missing state persistence indicators (setupDone, fromJson).',
  );

  // 9. Duration Tracking
  expect(
    content.contains('startedAt') ||
        content.contains('endedAt') ||
        content.contains('Duration') ||
        content.contains('DateTime') ||
        content.contains('timestamp'),
    isTrue,
    reason: 'Game $gameName is missing duration tracking (startedAt, endedAt).',
  );
}
