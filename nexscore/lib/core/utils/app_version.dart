class AppVersion {
  static const String current = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '0.1.0+1',
  );

  static bool get isPreRelease {
    // Versions starting with 0.x.x or containing 'b', 'dev', 'rc' are pre-releases
    return current.startsWith('0.') ||
        current.contains('b') ||
        current.contains('dev') ||
        current.contains('rc');
  }

  static String get displayVersion =>
      current.startsWith('v') ? current : 'v$current';
}
