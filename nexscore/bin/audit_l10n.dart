import 'dart:io';

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    // ignore: avoid_print
    print('Error: lib directory not found.');
    return;
  }

  final getRegex = RegExp(
    r"l10n\.get\(['"
    '"'
    r"]([^'"
    '"'
    r"]+)['"
    '"'
    r"]\)",
  );
  final getWithRegex = RegExp(
    r"l10n\.getWith\(['"
    '"'
    r"]([^'"
    '"'
    r"]+)['"
    '"'
    r"]\)",
  );

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

  print('Used keys: ${usedKeys.length}');

  // Read AppLocalizations to get defined keys
  final appLocalFile = File('lib/core/i18n/app_localizations.dart');
  if (!appLocalFile.existsSync()) {
    print('Error: app_localizations.dart not found.');
    return;
  }

  final l10nContent = appLocalFile.readAsStringSync();

  // Improved parsing
  final enMatch = RegExp(r"'en':\s*\{").firstMatch(l10nContent);
  final deMatch = RegExp(r"'de':\s*\{").firstMatch(l10nContent);

  if (enMatch == null || deMatch == null) {
    print('Could not find language sections');
    return;
  }

  String extractSection(int startPos) {
    int bracketCount = 0;
    for (int i = startPos; i < l10nContent.length; i++) {
      if (l10nContent[i] == '{') bracketCount++;
      if (l10nContent[i] == '}') {
        bracketCount--;
        if (bracketCount == 0) return l10nContent.substring(startPos, i + 1);
      }
    }
    return '';
  }

  final enSection = extractSection(enMatch.end - 1);
  final deSection = extractSection(deMatch.end - 1);

  final keyRegex = RegExp(
    r"['"
    '"'
    r"]([a-zA-Z0-9_]+)['"
    '"'
    r"]:",
  );
  final enKeys = keyRegex.allMatches(enSection).map((m) => m.group(1)!).toSet();
  final deKeys = keyRegex.allMatches(deSection).map((m) => m.group(1)!).toSet();

  final missingInEn = usedKeys.where((k) => !enKeys.contains(k)).toList();
  final missingInDe = usedKeys.where((k) => !deKeys.contains(k)).toList();

  // ignore: avoid_print
  print('Missing in EN: $missingInEn');
  // ignore: avoid_print
  print('Missing in DE: $missingInDe');
}
