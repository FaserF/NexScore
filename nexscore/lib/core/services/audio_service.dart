import 'package:audioplayers/audioplayers.dart';

enum SfxType {
  click,
  swipe,
  fanfare,
}

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;

  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  Future<void> play(SfxType type) async {
    if (!_enabled) return;

    String path;
    switch (type) {
      case SfxType.click:
        path = 'audio/click1.mp3';
        break;
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
