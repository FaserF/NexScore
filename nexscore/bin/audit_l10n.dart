import 'dart:io';

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('Error: lib directory not found.');
    return;
  }

  final getRegex = RegExp(r"l10n\.get\(['\"]([^'\"]+)['\"]");
  final getWithRegex = RegExp(r"l10n\.getWith\(['\"]([^'\"]+)['\"]");

  final usedKeys = <String>{};
  final files = libDir.listSync(recursive: true).whereType<File>();

  for (final file in files) {
    if (file.path.endsWith('.dart') && !file.path.contains('app_localizations.dart')) {
      final content = file.readAsStringSync();
      for (final match in getRegex.allMatches(content)) {
        usedKeys.add(match.group(1)!);
      }
      for (final match in getWithRegex.allMatches(content)) {
        usedKeys.add(match.group(1)!);
      }
    }
  }

  print('Used keys: ${usedKeys.length}');

  // Read AppLocalizations to get defined keys
  final appLocalFile = File('lib/core/i18n/app_localizations.dart');
  if (!appLocalFile.existsSync()) {
    print('Error: app_localizations.dart not found.');
    return;
  }

  final l10nContent = appLocalFile.readAsStringSync();

  // Very rough parsing of the map
  final enSection = l10nContent.split("'en':")[1].split("},")[0];
  final deSection = l10nContent.split("'de':")[1].split("},")[0];

  final keyRegex = RegExp(r"['\"]([a-zA-Z0-9_]+)['\"]:");
  final enKeys = keyRegex.allMatches(enSection).map((m) => m.group(1)!).toSet();
  final deKeys = keyRegex.allMatches(deSection).map((m) => m.group(1)!).toSet();

  final missingInEn = usedKeys.where((k) => !enKeys.contains(k)).toList();
  final missingInDe = usedKeys.where((k) => !deKeys.contains(k)).toList();

  print('Missing in EN: $missingInEn');
  print('Missing in DE: $missingInDe');
}
