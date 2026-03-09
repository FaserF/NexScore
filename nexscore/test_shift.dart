import 'dart:io';

void main() {
  final file = File('lib/core/i18n/app_localizations.dart');
  final lines = file.readAsLinesSync();

  String currentLang = '';
  Map<String, String> enKeys = {};
  Map<String, String> deKeys = {};

  for (final line in lines) {
    if (line.contains("'en': {")) {
      currentLang = 'en';
    } else if (line.contains("'de': {")) {
      currentLang = 'de';
    }

    // Some lines might be split. Let's just do a simple match for the key.
    final match = RegExp(r"^\s*'([^']+)':\s*'(.*)'").firstMatch(line);
    if (match != null) {
      final key = match.group(1)!;
      final val = match.group(2)!;
      if (currentLang == 'en') enKeys[key] = val;
      if (currentLang == 'de') deKeys[key] = val;
    }
  }

  print("EN keys: ${enKeys.length}, DE keys: ${deKeys.length}");

  for (int i = 1; i <= 30; i++) {
    String numStr = i.toString().padLeft(3, '0');
    String keyText = 'fq_card_rf${numStr}_text';

    final enText = enKeys[keyText];
    final deText = deKeys[keyText];

    String enSub = enText != null && enText.length > 30
        ? enText.substring(0, 30)
        : (enText ?? 'null');
    String deSub = deText != null && deText.length > 30
        ? deText.substring(0, 30)
        : (deText ?? 'null');

    print("$keyText EN: $enSub...");
    print("$keyText DE: $deSub...");
  }
}
