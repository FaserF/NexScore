import 'dart:io';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/core/i18n/app_localizations.dart';

void main() {
  group('i18n Parity', () {
    test('EN and DE have identical key sets', () {
      final enKeys = AppLocalizations.localizedValues['en']!.keys.toSet();
      final deKeys = AppLocalizations.localizedValues['de']!.keys.toSet();

      final missingInDe = enKeys.difference(deKeys);
      final missingInEn = deKeys.difference(enKeys);

      expect(
        missingInDe,
        isEmpty,
        reason: 'Keys in EN but missing in DE: $missingInDe',
      );
      expect(
        missingInEn,
        isEmpty,
        reason: 'Keys in DE but missing in EN: $missingInEn',
      );
    });

    test('no empty translation values in EN', () {
      final en = AppLocalizations.localizedValues['en']!;
      for (final entry in en.entries) {
        expect(
          entry.value.isNotEmpty,
          true,
          reason: 'EN key "${entry.key}" has empty value',
        );
      }
    });

    test('no empty translation values in DE', () {
      final de = AppLocalizations.localizedValues['de']!;
      for (final entry in de.entries) {
        expect(
          entry.value.isNotEmpty,
          true,
          reason: 'DE key "${entry.key}" has empty value',
        );
      }
    });

    test('all 9 game names and descriptions are present', () {
      final en = AppLocalizations.localizedValues['en']!;
      final gameKeys = [
        'game_wizard',
        'game_qwixx',
        'game_schafkopf',
        'game_kniffel',
        'game_phase10',
        'game_darts',
        'game_romme',
        'game_arschloch',
        'game_sipdeck',
        'game_wayquest',
      ];
      for (final key in gameKeys) {
        expect(en.containsKey(key), true, reason: 'Missing EN key: $key');
        expect(
          en.containsKey('desc_${key.replaceFirst('game_', '')}'),
          true,
          reason: 'Missing EN desc key for: $key',
        );
      }
    });

    test('localizedValues map has at least 2 locales', () {
      expect(AppLocalizations.localizedValues.length, greaterThanOrEqualTo(2));
    });

    test('get() returns key itself when key is missing', () {
      final l10n = AppLocalizations(const Locale('en'));
      expect(l10n.get('nonexistent_key_xyz'), 'nonexistent_key_xyz');
    });

    test('get() falls back to EN when locale is unsupported', () {
      final l10n = AppLocalizations(const Locale('fr'));
      expect(l10n.get('app_name'), 'NexScore');
    });

    test('getWith() interpolates arguments correctly', () {
      final l10n = AppLocalizations(const Locale('en'));
      final result = l10n.getWith('wizard_next_round', ['5']);
      expect(result, 'Enter Round 5');
    });

    test('getWith() handles multiple arguments', () {
      final l10n = AppLocalizations(const Locale('en'));
      final result = l10n.getWith('arschloch_exchange_p_to_a', [
        'Dave',
        'Alice',
      ]);
      expect(result, contains('Dave'));
      expect(result, contains('Alice'));
    });
    test('all keys used in codebase are defined in AppLocalizations', () {
      final libDir = Directory('lib');
      final getRegex = RegExp(r"l10n\.get\(['\\]?([^'\\]+)['\\]?\)");
      final getWithRegex = RegExp(r"l10n\.getWith\(['\\]?([^'\\]+)['\\]?");

      final usedKeys = <String>{};
      final files = libDir.listSync(recursive: true).whereType<File>();

      for (final file in files) {
        if (file.path.endsWith('.dart') &&
            !file.path.contains('app_localizations.dart')) {
          final content = file.readAsStringSync();
          for (final match in getRegex.allMatches(content)) {
            usedKeys.add(match.group(1)!);
          }
          for (final match in getWithRegex.allMatches(content)) {
            usedKeys.add(match.group(1)!);
          }
        }
      }

      final enKeys = AppLocalizations.localizedValues['en']!.keys.toSet();
      final deKeys = AppLocalizations.localizedValues['de']!.keys.toSet();

      final missingInEn = usedKeys.difference(enKeys);
      final missingInDe = usedKeys.difference(deKeys);

      expect(
        missingInEn,
        isEmpty,
        reason:
            'These keys are used in code but missing from EN localization: $missingInEn',
      );
      expect(
        missingInDe,
        isEmpty,
        reason:
            'These keys are used in code but missing from DE localization: $missingInDe',
      );
    });
  });
}
