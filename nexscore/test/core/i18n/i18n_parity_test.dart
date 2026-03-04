import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/core/i18n/app_localizations.dart';

void main() {
  group('i18n Key Parity', () {
    const supportedLocales = ['en', 'de'];

    test('all supported locales are present in localizedValues', () {
      for (final lang in supportedLocales) {
        expect(
          AppLocalizations.localizedValues.containsKey(lang),
          isTrue,
          reason: 'Locale "$lang" is missing from localizedValues map',
        );
      }
    });

    test('EN and DE have exactly the same set of keys', () {
      final enKeys = AppLocalizations.localizedValues['en']!.keys.toSet();
      final deKeys = AppLocalizations.localizedValues['de']!.keys.toSet();

      final missingInDe = enKeys.difference(deKeys);
      final missingInEn = deKeys.difference(enKeys);

      expect(
        missingInDe,
        isEmpty,
        reason: 'Keys in EN but MISSING in DE: $missingInDe',
      );
      expect(
        missingInEn,
        isEmpty,
        reason: 'Keys in DE but MISSING in EN: $missingInEn',
      );
    });

    test('no locale has any empty string values', () {
      for (final lang in supportedLocales) {
        final map = AppLocalizations.localizedValues[lang]!;
        final emptyKeys = map.entries
            .where((e) => e.value.trim().isEmpty)
            .map((e) => e.key)
            .toList();

        expect(
          emptyKeys,
          isEmpty,
          reason: 'Locale "$lang" has empty values for: $emptyKeys',
        );
      }
    });

    test('AppLocalizations.get falls back to EN for unknown locale', () {
      final loc = AppLocalizations(const Locale('fr'));
      expect(loc.get('app_name'), 'NexScore');
    });

    test('AppLocalizations.get returns key name when key is missing', () {
      final loc = AppLocalizations(const Locale('en'));
      expect(loc.get('nonexistent_key'), 'nonexistent_key');
    });

    test('AppLocalizations.getWith interpolates positional args correctly', () {
      final loc = AppLocalizations(const Locale('en'));
      final result = loc.getWith('wizard_next_round', ['5']);
      expect(result, 'Enter Round 5');
    });

    test('all game name keys are present in both locales', () {
      const gameKeys = [
        'game_wizard',
        'game_qwixx',
        'game_schafkopf',
        'game_kniffel',
        'game_phase10',
        'game_darts',
        'game_romme',
        'game_sipdeck',
        'game_arschloch',
      ];
      for (final lang in supportedLocales) {
        final map = AppLocalizations.localizedValues[lang]!;
        for (final key in gameKeys) {
          expect(
            map.containsKey(key),
            isTrue,
            reason: 'Game key "$key" missing in "$lang"',
          );
          expect(
            map[key]!.isNotEmpty,
            isTrue,
            reason: 'Empty value for "$key" in "$lang"',
          );
        }
      }
    });

    test('all game description keys are present in both locales', () {
      const descKeys = [
        'desc_wizard',
        'desc_qwixx',
        'desc_schafkopf',
        'desc_kniffel',
        'desc_phase10',
        'desc_darts',
        'desc_romme',
        'desc_sipdeck',
        'desc_arschloch',
      ];
      for (final lang in supportedLocales) {
        final map = AppLocalizations.localizedValues[lang]!;
        for (final key in descKeys) {
          expect(
            map.containsKey(key),
            isTrue,
            reason: 'Key "$key" missing in "$lang"',
          );
        }
      }
    });

    test('all SipDeck category keys are present in both locales', () {
      const catKeys = [
        'sipdeck_cat_warmUp',
        'sipdeck_cat_wildCards',
        'sipdeck_cat_flirty',
        'sipdeck_cat_barNight',
        'sipdeck_cat_laughs',
      ];
      for (final lang in supportedLocales) {
        final map = AppLocalizations.localizedValues[lang]!;
        for (final key in catKeys) {
          expect(
            map.containsKey(key),
            isTrue,
            reason: 'Key "$key" missing in "$lang"',
          );
        }
      }
    });

    test('EN locale has at least 70 keys (completeness check)', () {
      expect(
        AppLocalizations.localizedValues['en']!.length,
        greaterThanOrEqualTo(70),
        reason: 'EN locale seems incomplete – expected at least 70 keys',
      );
    });
  });
}
