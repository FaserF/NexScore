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
  // Expecting a button to finish the game prematurely
  expect(
    content.contains('Icons.check_circle_outline') ||
        content.contains('finishGame') ||
        content.contains('endGame'),
    isTrue,
    reason: 'Game $gameName is missing an Early Finish button or logic.',
  );

  // 2. Winner Celebration (Confetti & Sound)
  expect(
    content.contains('WinnerConfettiController') ||
        content.contains('WinnerOverlay') ||
        content.contains('WinnerDialog') ||
        content.contains('WinnerScreen'),
    isTrue,
    reason: 'Game $gameName is missing winner celebration (Confetti/Overlay).',
  );

  // Checking for audio service or fanfare sound usage for winner
  expect(
    content.contains('AudioService') ||
        content.contains('SfxType.fanfare') ||
        content.contains('play(SfxType.fanfare)') ||
        content.contains('winnerSound'),
    isTrue,
    reason: 'Game $gameName is missing winner sound (e.g. SfxType.fanfare).',
  );

  // 3. Multiplayer Support
  expect(
    content.contains('MultiplayerClientOverlay') ||
        content.contains('Multiplayer'),
    isTrue,
    reason:
        'Game $gameName is missing MultiplayerClientOverlay or multiplayer integration.',
  );

  // 4. Reset Game
  expect(
    content.contains('Icons.refresh') && content.contains('reset'),
    isTrue,
    reason: 'Game $gameName is missing a Game Reset button (Icons.refresh).',
  );

  // 5. Undo Action
  expect(
    content.contains('Icons.undo') && content.contains('undo'),
    isTrue,
    reason: 'Game $gameName is missing an Undo button (Icons.undo).',
  );

  // 6. Configurable Settings
  expect(
    content.contains('Icons.settings') || content.contains('Icons.edit_note'),
    isTrue,
    reason: 'Game $gameName is missing a Settings/Configuration button.',
  );

  // 7. Help Documentation
  expect(
    content.contains('Icons.help_outline') &&
        content.contains('url_launcher') &&
        content.contains('github.io/NexScore/docs'),
    isTrue,
    reason:
        'Game $gameName is missing a Help button linking to GitHub Pages docs.',
  );
}
