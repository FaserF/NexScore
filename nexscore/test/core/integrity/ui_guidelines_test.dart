import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'UX Guidelines: Game screens should not use unstyled plain text buttons for primary actions',
    () {
      final dir = Directory('lib/features/games');
      if (!dir.existsSync()) return;

      final dartFiles = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('_screen.dart'))
          .toList();

      // Contexts where a plain TextButton is acceptable (like Dialogs)
      final exceptions = [
        'AlertDialog',
        'showDialog',
        'actions: [',
        'actions: <Widget>[',
        'showModalBottomSheet',
      ];

      for (final file in dartFiles) {
        final content = file.readAsStringSync();

        // Ignore explicitly annotated TextButtons
        final cleanContent = content.replaceAll(
          RegExp(r'// ignore: unstyled_button\s*\n\s*TextButton\('),
          '',
        );

        final matches = RegExp(r'TextButton\s*\(').allMatches(cleanContent);
        for (final match in matches) {
          // Look at the 350 characters before the TextButton to see if it's inside a dialog
          final start = (match.start - 350).clamp(0, content.length).toInt();
          final contextBefore = cleanContent.substring(start, match.start);

          // Also look slightly ahead just in case
          final end = (match.end + 150).clamp(0, content.length).toInt();
          final contextAfter = cleanContent.substring(match.end, end);

          bool isException = exceptions.any(
            (ext) => contextBefore.contains(ext),
          );

          // If it's a TextButton.icon or similar variant, the regex won't match "TextButton("
          // because of the dot, but let's be safe:
          bool isIconVariant = contextBefore.endsWith('.');

          if (!isException && !isIconVariant) {
            // Check if it has an icon inside its children somehow (rare for TextButton, usually TextButton.icon is used)
            if (!contextAfter.contains('Icon(')) {
              fail(
                'Found an unstyled plain TextButton used outside of a dialog in:\n'
                'File: ${file.path}\n'
                'Context: "...${cleanContent.substring(match.start, match.start + 50)}..."\n\n'
                'UX Guidelines require primary screen actions to use FilledButton, '
                'OutlinedButton, or TextButton.icon() to avoid looking like plain text. '
                'If this is intentional, add // ignore: unstyled_button directly above it.',
              );
            }
          }
        }
      }
    },
  );
}
