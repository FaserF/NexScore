import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A banner that displays "DEV" or "BETA" depending on the environment.
/// "DEV" is shown in debug mode.
/// "BETA" is shown if the --dart-define=IS_BETA=true flag is set.
class EnvironmentBanner extends StatelessWidget {
  final Widget child;

  const EnvironmentBanner({super.key, required this.child});

  static const bool isBeta = bool.fromEnvironment(
    'IS_BETA',
    defaultValue: false,
  );

  static const bool isDev = bool.fromEnvironment(
    'IS_DEV',
    defaultValue: false,
  );

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode && !isBeta && !isDev) return child;

    final String label = (kDebugMode || isDev) ? 'DEV' : 'BETA';
    final Color color = (kDebugMode || isDev) ? Colors.orange : Colors.blue;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          child,
          Positioned(
            top: 0,
            right: 0,
            child: IgnorePointer(
              child: ClipRect(
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Banner(
                    message: label,
                    location: BannerLocation.topEnd,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
