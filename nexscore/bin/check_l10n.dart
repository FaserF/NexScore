// ignore_for_file: avoid_print
import 'package:nexscore/core/i18n/app_localizations.dart';

void main() {
  final en = AppLocalizations.localizedValues['en']!;
  final de = AppLocalizations.localizedValues['de']!;

  print('EN Keys: ${en.length}');
  print('DE Keys: ${de.length}');

  final missingInDe = en.keys.where((k) => !de.keys.contains(k)).toList();
  print('Missing in DE: $missingInDe');
}
