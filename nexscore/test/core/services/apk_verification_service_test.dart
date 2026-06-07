import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/core/services/apk_verification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('de.fabiseitz.nex_score/apk_verification');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getApkSha256') {
        return 'a1b2c3d4e5f6';
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('verifyApk returns notAndroid on non-Android platform tests', () async {
    final result = await ApkVerificationService.verifyApk();
    expect(result, equals(ApkVerificationResult.notAndroid));
  });
}
