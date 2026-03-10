import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class TtsService {
  final FlutterTts _flutterTts;
  bool _isSpeaking = false;

  TtsService({FlutterTts? tts}) : _flutterTts = tts ?? FlutterTts() {
    _initTts();
  }

  Future<void> _initTts() async {
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      debugPrint("TTS Error: $msg");
    });
  }

  Future<void> setLanguage(String languageCode) async {
    await _flutterTts.setLanguage(languageCode);
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await stop();
    final expandedText = _expandAbbreviations(text);
    await _flutterTts.speak(expandedText);
  }

  String _expandAbbreviations(String text) {
    // Insert a space between a trailing digit and an abbreviation so that
    // "10s" is treated the same as "10 s" before pattern matching.
    String result = text.replaceAllMapped(
      RegExp(r'(\d)(sek|sec|min|km/h|km|[smh])(?!\w)', caseSensitive: false),
      (m) => '${m.group(1)} ${m.group(2)}',
    );

    final Map<String, String> expansions = {
      r'\bs\b': 'seconds',
      r'\bsec\b': 'seconds',
      r'\bsek\b': 'Sekunden',
      r'\bmin\b': 'minutes',
      r'\bh\b': 'hours',
      r'\bkm/h\b': 'kilometers per hour',
      r'\bkm\b': 'kilometers',
      r'\bm\b': 'meters',
    };

    expansions.forEach((pattern, replacement) {
      result = result.replaceAllMapped(
        RegExp(pattern, caseSensitive: false),
        (_) => replacement,
      );
    });

    return result;
  }

  Future<void> stop() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
    }
  }

  bool get isSpeaking => _isSpeaking;
}
