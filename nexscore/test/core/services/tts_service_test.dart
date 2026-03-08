import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/core/services/tts_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

class FakeFlutterTts extends Fake implements FlutterTts {
  @override
  void setStartHandler(Function callback) {}
  @override
  void setCompletionHandler(Function callback) {}
  @override
  void setErrorHandler(Function(dynamic message) callback) {}
  @override
  Future<dynamic> setLanguage(String language) async => true;
  @override
  Future<dynamic> speak(String text, {bool? focus}) async => true;
  @override
  Future<dynamic> stop() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('TtsService Tests', () {
    test('TtsService can be instantiated', () {
      final service = TtsService(tts: FakeFlutterTts());
      expect(service, isNotNull);
      expect(service.isSpeaking, isFalse);
    });

    test('TtsService.stop() can be called even if not speaking', () async {
      final service = TtsService(tts: FakeFlutterTts());
      await expectLater(service.stop(), completes);
      expect(service.isSpeaking, isFalse);
    });
  });
}
