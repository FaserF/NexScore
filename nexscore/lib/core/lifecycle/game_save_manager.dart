import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/persistence_provider.dart';

// Game Providers
import '../../features/games/wizard_digital/providers/wizard_digital_provider.dart';
import '../../features/games/kniffel_digital/providers/kniffel_digital_provider.dart';
import '../../features/games/qwixx_digital/providers/qwixx_digital_provider.dart';
import '../../features/games/arschloch_digital/providers/arschloch_digital_provider.dart';
import '../../features/games/romme_digital/providers/romme_digital_provider.dart';
import '../../features/games/phase10_digital/providers/phase10_digital_provider.dart';
import '../../features/games/sipdeck/providers/sipdeck_provider.dart';
import '../../features/games/buzztap/providers/buzztap_provider.dart';
import '../../features/games/wayquest/providers/wayquest_provider.dart';

/// Handles saving the current active game state to persistent storage.
class GameSaveManager {
  static Future<void> saveCurrentGame(Ref ref) async {
    final gameId = ref.read(activeGameIdProvider);
    if (gameId == null) return;

    final service = ref.read(persistenceServiceProvider);
    Map<String, dynamic>? stateMap;

    try {
      if (gameId == 'wizard_digital') {
        stateMap = ref.read(wizardDigitalProvider).toMap();
      } else if (gameId == 'kniffel_digital') {
        stateMap = ref.read(kniffelDigitalProvider).toMap();
      } else if (gameId == 'qwixx_digital') {
        stateMap = ref.read(qwixxDigitalProvider).toMap();
      } else if (gameId == 'arschloch_digital') {
        stateMap = ref.read(arschlochDigitalProvider).toMap();
      } else if (gameId == 'romme_digital') {
        stateMap = ref.read(rommeDigitalProvider).toMap();
      } else if (gameId == 'phase10_digital') {
        stateMap = ref.read(phase10DigitalProvider).toMap();
      } else if (gameId == 'sipdeck') {
        stateMap = ref.read(sipDeckStateProvider).toMap();
      } else if (gameId == 'buzztap') {
        stateMap = ref.read(buzzTapStateProvider).toMap();
      } else if (gameId == 'wayquest') {
        stateMap = ref.read(wayQuestStateProvider).toMap();
      }

      // schafkopf_digital omitted for now if not fully serializable yet

      if (stateMap != null) {
        await service.saveGameState(gameId, stateMap);
        debugPrint('Saved game state for $gameId');
      }
    } catch (e) {
      debugPrint('Failed to auto-save game $gameId: $e');
    }
  }
}
