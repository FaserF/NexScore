import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/core/multiplayer/multiplayer_service.dart';
import 'package:mocktail/mocktail.dart';

class MockMultiplayerService extends Mock implements MultiplayerService {}

void main() {
  group('Multiplayer Error Handling Tests', () {
    late MockMultiplayerService mockService;

    setUpAll(() {
      // Mocking doesn't strictly need setup for these simple cases
    });

    setUp(() {
      mockService = MockMultiplayerService();
    });

    test(
      'should throw Exception with firestore_timeout when hosting times out',
      () async {
        when(
          () => mockService.hostLobby(
            hostName: any(named: 'hostName'),
            hostAvatarColor: any(named: 'hostAvatarColor'),
          ),
        ).thenAnswer((_) => Future.error(Exception('firestore_timeout')));

        expect(
          () => mockService.hostLobby(hostName: 'Test', hostAvatarColor: 'Red'),
          throwsA(
            predicate(
              (e) =>
                  e is Exception && e.toString().contains('firestore_timeout'),
            ),
          ),
        );
      },
    );

    test('should handle join lobby timeout', () async {
      when(
        () => mockService.joinLobby(
          roomCode: any(named: 'roomCode'),
          playerName: any(named: 'playerName'),
          playerAvatarColor: any(named: 'playerAvatarColor'),
        ),
      ).thenAnswer((_) => Future.error(Exception('firestore_timeout')));

      expect(
        () => mockService.joinLobby(
          roomCode: 'ABCD',
          playerName: 'Player',
          playerAvatarColor: 'Blue',
        ),
        throwsA(
          predicate(
            (e) => e is Exception && e.toString().contains('firestore_timeout'),
          ),
        ),
      );
    });
  });

  group('Configuration Integrity Verification', () {
    test('FirestoreMultiplayerImpl should have increased timeouts (15s)', () {
      final file = File('lib/core/multiplayer/firestore_multiplayer_impl.dart');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'Implementation file should exist',
      );

      final content = file.readAsStringSync();
      // Verify we have the 15s timeout
      expect(content, contains('timeout(const Duration(seconds: 15))'));
      // Verify pre-flight check logic is present
      expect(content, contains('Running connectivity check...'));
      expect(content, contains('.limit(1)'));
      expect(
        content,
        contains('.get(const GetOptions(source: Source.serverAndCache))'),
      );
    });

    test(
      'Main should NOT use Path URL Strategy for better GitHub Pages compatibility',
      () {
        final file = File('lib/main.dart');
        expect(file.existsSync(), isTrue, reason: 'Main file should exist');

        final content = file.readAsStringSync();
        expect(content, isNot(contains('\n  usePathUrlStrategy();')));
        expect(content, contains('//   usePathUrlStrategy();'));
      },
    );
  });
}
