import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/core/utils/app_logger.dart';

void main() {
  group('AppLogger Tests', () {
    setUp(() {
      AppLogger.clearLogs();
    });

    test('addLog adds logs to the system', () {
      AppLogger.addLog('Test message');
      expect(AppLogger.debugLogs.length, 1);
      expect(AppLogger.debugLogs.first, contains('Test message'));
    });

    test('Log buffer truncates after 5000 lines', () {
      // Add exactly 5000 logs
      for (int i = 0; i < 5000; i++) {
        AppLogger.addLog('Log $i');
      }
      expect(AppLogger.debugLogs.length, 5000);

      // Add 5001st log - should trigger truncation of 1000 logs
      AppLogger.addLog('Log 5000');

      // Expected length: 5001 original logs - 1000 removed = 4001
      expect(AppLogger.debugLogs.length, 4001);
      // The first log should now be the 1000th one
      expect(AppLogger.debugLogs.first, contains('Log 1000'));
    });

    test('Debug mode toggle works', () {
      AppLogger.debugMode = true;
      expect(AppLogger.debugMode, true);
      AppLogger.debugMode = false;
      expect(AppLogger.debugMode, false);
    });
  });
}
