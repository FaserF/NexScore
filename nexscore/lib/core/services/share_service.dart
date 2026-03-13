import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../i18n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class ShareService {
  final ScreenshotController _screenshotController = ScreenshotController();

  ScreenshotController get controller => _screenshotController;

  /// Captures a [Widget] by wrapping it in a [Screenshot] widget and shares it.
  Future<void> shareWidget(
    BuildContext context,
    Widget widget, {
    String? text,
  }) async {
    try {
      final locale = Localizations.maybeLocaleOf(context) ?? const Locale('en');
      final theme = Theme.of(context);

      final imageBytes = await _screenshotController.captureFromWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('de')],
          locale: locale,
          home: Material(color: Colors.transparent, child: widget),
        ),
        context: context,
        delay: const Duration(
          milliseconds: 500,
        ), // Increased delay for rendering
      );

      // Note: captureFromWidget in screenshot 3.0.0 returns Uint8List,
      // not Uint8List?, so a null check is redundant. If it fails,
      // it should throw an exception which will be caught below.

      if (kIsWeb) {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                imageBytes,
                mimeType: 'image/png',
                name: 'nexscore_share_${const Uuid().v4().substring(0, 8)}.png',
              ),
            ],
            subject: text,
          ),
        );
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = await File(
          '${tempDir.path}/nexscore_share_${const Uuid().v4().substring(0, 8)}.png',
        ).create();
        await file.writeAsBytes(imageBytes);

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: text,
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('Share error type: ${e.runtimeType}');
      debugPrint('Share error: $e');
      if (kDebugMode) {
        debugPrint('Stack trace: $stack');
      }

      // On Web, if image capture fails (common with CanvasKit/readPixels),
      // we attempt to share just the text as a fallback.
      if (kIsWeb && text != null && text.isNotEmpty) {
        try {
          await SharePlus.instance.share(ShareParams(subject: text));
          return; // Successfully fell back to text sharing
        } catch (fallbackError) {
          debugPrint('Text fallback share also failed: $fallbackError');
        }
      }

      String displayError = e.toString();
      // Handle minified exceptions on web by checking for properties if possible
      if (displayError.contains('minified')) {
        displayError =
            'A platform error occurred during sharing. Please try again.';
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $displayError'),
            action: SnackBarAction(
              label: 'Details',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Share Error Details'),
                    content: SingleChildScrollView(
                      child: SelectableText(
                        'Error: $e\n\nType: ${e.runtimeType}\n\nStack: $stack',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    }

  }

  /// Shares a captured file path directly.
  Future<void> shareFile(String filePath, {String? text}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        subject: text,
      ),
    );
  }
}

// Provider defined in lib/core/providers/share_provider.dart
