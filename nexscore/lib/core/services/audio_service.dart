import 'package:audioplayers/audioplayers.dart';

enum SfxType { swipe, fanfare }

class AudioService {
  final AudioPlayer _player;
  bool _enabled = true;
  bool _beepEnabled = true;
  bool _fanfareEnabled = true;
  bool _otherEnabled = true;

  AudioService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  void setGranularEnabled({
    required bool beep,
    required bool fanfare,
    required bool other,
  }) {
    _beepEnabled = beep;
    _fanfareEnabled = fanfare;
    _otherEnabled = other;
  }

  Future<void> play(SfxType type) async {
    if (!_enabled) return;
    if (type == SfxType.swipe && !_beepEnabled) return;
    if (type == SfxType.fanfare && !_fanfareEnabled) return;
    // For now other is just a catch-all but we can add more types
    if (type != SfxType.swipe && type != SfxType.fanfare && !_otherEnabled) return;

    String path;
    switch (type) {
      case SfxType.swipe:
        path = 'audio/beep1.mp3';
        break;
      case SfxType.fanfare:
        path = 'audio/fanfare1.mp3';
        break;
    }

    try {
      await _player.play(AssetSource(path));
    } catch (e) {
      // Silent fail
    }
  }

  void dispose() {
    _player.dispose();
  }
}
