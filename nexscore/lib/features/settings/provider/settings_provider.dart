import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/app_logger.dart';

/// Settings state model.
class Settings {
  final ThemeMode themeMode;
  final Locale? locale;
  final String hostName;
  final String hostColor;
  final bool sfxEnabled;
  final bool sfxBeepEnabled;
  final bool sfxFanfareEnabled;
  final bool sfxOtherEnabled;
  final bool debugMode;
  final bool autoBackupEnabled;
  final String autoBackupFrequency; // 'daily', 'weekly', 'manual'
  final DateTime? lastBackupTime;
  final String? lastBackupProvider; // 'google', 'github'

  const Settings({
    required this.themeMode,
    this.locale,
    this.hostName = 'Player',
    this.hostColor = '#4287f5',
    this.sfxEnabled = true,
    this.sfxBeepEnabled = true,
    this.sfxFanfareEnabled = true,
    this.sfxOtherEnabled = true,
    this.debugMode = false,
    this.autoBackupEnabled = true,
    this.autoBackupFrequency = 'daily',
    this.lastBackupTime,
    this.lastBackupProvider,
  });

  Settings copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool clearLocale = false,
    String? hostName,
    String? hostColor,
    bool? sfxEnabled,
    bool? sfxBeepEnabled,
    bool? sfxFanfareEnabled,
    bool? sfxOtherEnabled,
    bool? debugMode,
    bool? autoBackupEnabled,
    String? autoBackupFrequency,
    DateTime? lastBackupTime,
    String? lastBackupProvider,
  }) {
    return Settings(
      themeMode: themeMode ?? this.themeMode,
      locale: clearLocale ? null : (locale ?? this.locale),
      hostName: hostName ?? this.hostName,
      hostColor: hostColor ?? this.hostColor,
      sfxEnabled: sfxEnabled ?? this.sfxEnabled,
      sfxBeepEnabled: sfxBeepEnabled ?? this.sfxBeepEnabled,
      sfxFanfareEnabled: sfxFanfareEnabled ?? this.sfxFanfareEnabled,
      sfxOtherEnabled: sfxOtherEnabled ?? this.sfxOtherEnabled,
      debugMode: debugMode ?? this.debugMode,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      autoBackupFrequency: autoBackupFrequency ?? this.autoBackupFrequency,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      lastBackupProvider: lastBackupProvider ?? this.lastBackupProvider,
    );
  }
}

/// Provider for app settings using the modern Notifier pattern.
final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<Settings> {
  static const _themeKey = 'settings_theme_mode';
  static const _localeKey = 'settings_locale';
  static const _hostNameKey = 'settings_host_name';
  static const _hostColorKey = 'settings_host_color';
  static const _sfxEnabledKey = 'settings_sfx_enabled';
  static const _sfxBeepKey = 'settings_sfx_beep_enabled';
  static const _sfxFanfareKey = 'settings_sfx_fanfare_enabled';
  static const _sfxOtherKey = 'settings_sfx_other_enabled';
  static const _debugModeKey = 'settings_debug_mode';
  static const _autoBackupEnabledKey = 'settings_auto_backup_enabled';
  static const _autoBackupFreqKey = 'settings_auto_backup_freq';
  static const _lastBackupTimeKey = 'settings_last_backup_time';
  static const _lastBackupProviderKey = 'settings_last_backup_provider';

  @override
  Settings build() {
    // Initial state is system theme and default locale.
    // _loadSettings will update this asynchronously.
    _loadSettings();
    return Settings(
      themeMode: ThemeMode.system,
      hostName: _generateDefaultName(),
      sfxEnabled: true,
      sfxBeepEnabled: true,
      sfxFanfareEnabled: true,
      sfxOtherEnabled: true,
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_themeKey);
    final themeMode = themeIndex != null
        ? ThemeMode.values[themeIndex]
        : ThemeMode.system;

    final localeCode = prefs.getString(_localeKey);
    final locale = localeCode != null ? Locale(localeCode) : null;

    final hostName = prefs.getString(_hostNameKey) ?? _generateDefaultName();
    final hostColor = prefs.getString(_hostColorKey) ?? '#4287f5';
    final sfxEnabled = prefs.getBool(_sfxEnabledKey) ?? true;
    final sfxBeepEnabled = prefs.getBool(_sfxBeepKey) ?? true;
    final sfxFanfareEnabled = prefs.getBool(_sfxFanfareKey) ?? true;
    final sfxOtherEnabled = prefs.getBool(_sfxOtherKey) ?? true;
    final debugMode = prefs.getBool(_debugModeKey) ?? false;
    AppLogger.debugMode = debugMode;
    final autoBackupEnabled = prefs.getBool(_autoBackupEnabledKey) ?? true;
    final autoBackupFreq = prefs.getString(_autoBackupFreqKey) ?? 'daily';
    final lastBackupTimeStr = prefs.getString(_lastBackupTimeKey);
    final lastBackupTime = lastBackupTimeStr != null
        ? DateTime.parse(lastBackupTimeStr)
        : null;
    final lastBackupProvider = prefs.getString(_lastBackupProviderKey);

    state = Settings(
      themeMode: themeMode,
      locale: locale,
      hostName: hostName,
      hostColor: hostColor,
      sfxEnabled: sfxEnabled,
      sfxBeepEnabled: sfxBeepEnabled,
      sfxFanfareEnabled: sfxFanfareEnabled,
      sfxOtherEnabled: sfxOtherEnabled,
      debugMode: debugMode,
      autoBackupEnabled: autoBackupEnabled,
      autoBackupFrequency: autoBackupFreq,
      lastBackupTime: lastBackupTime,
      lastBackupProvider: lastBackupProvider,
    );
  }

  String _generateDefaultName() {
    final random = math.Random();
    final number = 10000 + random.nextInt(90000); // 5-digit random number
    return 'Player#$number';
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, locale.languageCode);
    }
    state = state.copyWith(locale: locale, clearLocale: locale == null);
  }

  Future<void> setHostName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hostNameKey, name);
    state = state.copyWith(hostName: name);
  }

  Future<void> setHostColor(String color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hostColorKey, color);
    state = state.copyWith(hostColor: color);
  }


  Future<void> setSfxEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxEnabledKey, enabled);
    state = state.copyWith(sfxEnabled: enabled);
  }

  Future<void> setSfxBeepEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxBeepKey, enabled);
    state = state.copyWith(sfxBeepEnabled: enabled);
  }

  Future<void> setSfxFanfareEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxFanfareKey, enabled);
    state = state.copyWith(sfxFanfareEnabled: enabled);
  }

  Future<void> setSfxOtherEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxOtherKey, enabled);
    state = state.copyWith(sfxOtherEnabled: enabled);
  }

  Future<void> setDebugMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debugModeKey, enabled);
    AppLogger.debugMode = enabled;
    state = state.copyWith(debugMode: enabled);
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupEnabledKey, enabled);
    state = state.copyWith(autoBackupEnabled: enabled);
  }

  Future<void> setAutoBackupFrequency(String freq) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_autoBackupFreqKey, freq);
    state = state.copyWith(autoBackupFrequency: freq);
  }

  Future<void> updateLastBackupMetadata(DateTime time, String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupTimeKey, time.toIso8601String());
    await prefs.setString(_lastBackupProviderKey, provider);
    state = state.copyWith(lastBackupTime: time, lastBackupProvider: provider);
  }

  /// Updates hostName if it currently follows the 'Player#12345' default pattern.
  Future<void> updateHostNameIfDefault(String newName) async {
    final name = state.hostName;
    final defaultPattern = RegExp(r'^Player#\d{5}$');
    if (defaultPattern.hasMatch(name) && newName.isNotEmpty) {
      await setHostName(newName);
    }
  }
}
