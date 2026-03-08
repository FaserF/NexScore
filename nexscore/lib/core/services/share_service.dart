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
  /// Note: On Web, the behavioral fallback might differ based on browser support.
  Future<void> shareWidget(
    BuildContext context,
    Widget widget, {
    String? text,
  }) async {
    try {
      final imageBytes = await _screenshotController.captureFromWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: Theme.of(context),
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('de')],
          locale: Localizations.localeOf(context),
          home: Material(color: Colors.transparent, child: widget),
        ),
        context: context,
        delay: const Duration(
          milliseconds: 500,
        ), // Increased delay for rendering
      );

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
          ShareParams(files: [XFile(file.path)], subject: text),
        );
      }
    } catch (e) {
      debugPrint('Share error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
      }
    }
  }

  /// Shares a captured file path directly.
  Future<void> shareFile(String filePath, {String? text}) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(filePath)], subject: text),
    );
  }
}

// Provider defined in lib/core/providers/share_provider.dart
