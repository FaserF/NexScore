import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/core/multiplayer/firestore_multiplayer_impl.dart';

void main() {
  group('FirestoreMultiplayerImpl Firebase Config Tests', () {
    test(
      'hostLobby throws FIREBASE_NOT_CONFIGURED when no Firebase apps initialized',
      () async {
        final service = FirestoreMultiplayerImpl();

        expect(
          () => service.hostLobby(hostName: 'Test', hostAvatarColor: '#000000'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('FIREBASE_NOT_CONFIGURED'),
            ),
          ),
        );
      },
    );

    test(
      'joinLobby throws FIREBASE_NOT_CONFIGURED when no Firebase apps initialized',
      () async {
        final service = FirestoreMultiplayerImpl();

        expect(
          () => service.joinLobby(
            roomCode: '12345',
            playerName: 'Test',
            playerAvatarColor: '#000000',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('FIREBASE_NOT_CONFIGURED'),
            ),
          ),
        );
      },
    );
  });
}
