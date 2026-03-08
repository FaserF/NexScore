import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tts_service.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});

/// A simple notifier to track the TTS toggle state per game session.
/// The global preference is stored in settingsProvider.
class TtsActiveNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void setEnabled(bool value) => state = value;
}

final ttsActiveProvider = NotifierProvider<TtsActiveNotifier, bool>(
  TtsActiveNotifier.new,
);
