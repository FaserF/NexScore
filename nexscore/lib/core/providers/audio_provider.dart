import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio_service.dart';
import '../../features/settings/provider/settings_provider.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  final settings = ref.watch(settingsProvider);
  service.setEnabled(settings.sfxEnabled);
  ref.onDispose(() => service.dispose());
  return service;
});
