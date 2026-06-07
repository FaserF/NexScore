import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexscore/core/storage/state_persistence_service.dart';
import 'package:nexscore/features/settings/provider/settings_provider.dart';

void main() {
  group('Settings & State Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Settings model defaults and serialization', () {
      const settings = Settings(themeMode: ThemeMode.dark);
      expect(settings.themeMode, ThemeMode.dark);
      expect(settings.hostName, 'Player');
      expect(settings.sfxEnabled, true);

      final map = settings.toMap();
      expect(map['themeMode'], ThemeMode.dark.index);
      expect(map['hostName'], 'Player');
      expect(map['sfxEnabled'], true);

      final copy = settings.copyWith(hostName: 'Bob');
      expect(copy.hostName, 'Bob');
      expect(copy.themeMode, ThemeMode.dark);
    });

    test('StatePersistenceService saves and loads game states', () async {
      final service = StatePersistenceService();
      await service.clearAll();

      final gameId = 'game_123';
      final gameState = {'score': 42, 'level': 3};

      await service.saveGameState(gameId, gameState);
      expect(await service.getLastGameId(), gameId);

      final loadedState = await service.loadGameState(gameId);
      expect(loadedState, isNotNull);
      expect(loadedState!['score'], 42);
      expect(loadedState['level'], 3);

      final playerIds = ['p1', 'p2'];
      await service.saveActivePlayerIds(playerIds);
      expect(await service.loadActivePlayerIds(), playerIds);

      await service.clearGameState(gameId);
      expect(await service.loadGameState(gameId), isNull);
      expect(await service.getLastGameId(), isNull);
      expect(await service.loadActivePlayerIds(), isEmpty);
    });

    test('SettingsNotifier integration with SharedPreferences', () async {
      // Mock initial preferences
      SharedPreferences.setMockInitialValues({
        'settings_theme_mode': ThemeMode.dark.index,
        'settings_host_name': 'Player#12345',
        'settings_sfx_enabled': false,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Read the provider to trigger build() and starting _loadSettings()
      container.read(settingsProvider);

      // Wait for SettingsNotifier._loadSettings() to finish
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(settingsProvider.notifier);

      // Verify loaded values
      var currentSettings = container.read(settingsProvider);
      expect(currentSettings.themeMode, ThemeMode.dark);
      expect(currentSettings.hostName, 'Player#12345');
      expect(currentSettings.sfxEnabled, false);

      // Test modifications
      await notifier.setThemeMode(ThemeMode.light);
      await notifier.setHostName('Bob');
      await notifier.setSfxEnabled(true);
      await notifier.setLocale(const Locale('en'));

      currentSettings = container.read(settingsProvider);
      expect(currentSettings.themeMode, ThemeMode.light);
      expect(currentSettings.hostName, 'Bob');
      expect(currentSettings.sfxEnabled, true);
      expect(currentSettings.locale?.languageCode, 'en');

      // Verify SharedPreferences updated
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('settings_theme_mode'), ThemeMode.light.index);
      expect(prefs.getString('settings_host_name'), 'Bob');
      expect(prefs.getBool('settings_sfx_enabled'), true);
      expect(prefs.getString('settings_locale'), 'en');

      // Test updateHostNameIfDefault (should NOT update now since hostName is 'Bob')
      await notifier.updateHostNameIfDefault('Charlie');
      expect(container.read(settingsProvider).hostName, 'Bob');

      // Reset hostName to default pattern to test updateHostNameIfDefault
      await notifier.setHostName('Player#54321');
      await notifier.updateHostNameIfDefault('Charlie');
      expect(container.read(settingsProvider).hostName, 'Charlie');
    });

    test('SettingsNotifier importSettings updates state and SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      // Read to trigger build
      container.read(settingsProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(settingsProvider.notifier);

      final importData = {
        'themeMode': ThemeMode.dark.index,
        'hostName': 'ImportedPlayer',
        'sfxEnabled': false,
        'autoBackupEnabled': false,
        'autoBackupFrequency': 'weekly',
      };

      await notifier.importSettings(importData);

      final currentSettings = container.read(settingsProvider);
      expect(currentSettings.themeMode, ThemeMode.dark);
      expect(currentSettings.hostName, 'ImportedPlayer');
      expect(currentSettings.sfxEnabled, false);
      expect(currentSettings.autoBackupEnabled, false);
      expect(currentSettings.autoBackupFrequency, 'weekly');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('settings_theme_mode'), ThemeMode.dark.index);
      expect(prefs.getString('settings_host_name'), 'ImportedPlayer');
      expect(prefs.getBool('settings_sfx_enabled'), false);
    });
  });
}
