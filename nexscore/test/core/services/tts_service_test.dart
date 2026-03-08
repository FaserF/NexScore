import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/core/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('TtsService Tests', () {
    test('TtsService can be instantiated', () {
      final service = TtsService();
      expect(service, isNotNull);
      expect(service.isSpeaking, isFalse);
    });

    test('TtsService.stop() can be called even if not speaking', () async {
      final service = TtsService();
      await expectLater(service.stop(), completes);
      expect(service.isSpeaking, isFalse);
    });
  });
}
