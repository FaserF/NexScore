import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/core/services/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';

class FakeAudioPlayer extends Fake implements AudioPlayer {
  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioService Tests', () {
    test('AudioService can be instantiated', () {
      final service = AudioService(player: FakeAudioPlayer());
      expect(service, isNotNull);
    });

    test('AudioService.setEnabled toggle works', () {
      final service = AudioService(player: FakeAudioPlayer());
      service.setEnabled(false);
      expect(() => service.play(SfxType.swipe), returnsNormally);
    });

    test('AudioService.play() executes without error', () async {
      final service = AudioService(player: FakeAudioPlayer());
      await expectLater(service.play(SfxType.swipe), completes);
    });
  });
}
