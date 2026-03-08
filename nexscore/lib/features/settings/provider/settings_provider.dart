import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings state model.
class Settings {
  final ThemeMode themeMode;
  final Locale? locale;
  final String hostName;
  final String hostColor;
  final bool ttsEnabled;
  final bool sfxEnabled;

  const Settings({
    required this.themeMode,
    this.locale,
    this.hostName = 'Player',
    this.hostColor = '#4287f5',
    this.ttsEnabled = false,
    this.sfxEnabled = true,
  });

  Settings copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool clearLocale = false,
    String? hostName,
    String? hostColor,
    bool? ttsEnabled,
    bool? sfxEnabled,
  }) {
    return Settings(
      themeMode: themeMode ?? this.themeMode,
      locale: clearLocale ? null : (locale ?? this.locale),
      hostName: hostName ?? this.hostName,
      hostColor: hostColor ?? this.hostColor,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      sfxEnabled: sfxEnabled ?? this.sfxEnabled,
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
  static const _ttsEnabledKey = 'settings_tts_enabled';
  static const _sfxEnabledKey = 'settings_sfx_enabled';

  @override
  Settings build() {
    // Initial state is system theme and default locale.
    // _loadSettings will update this asynchronously.
    _loadSettings();
    return Settings(
      themeMode: ThemeMode.system,
      hostName: _generateDefaultName(),
      ttsEnabled: false,
      sfxEnabled: true,
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
    final ttsEnabled = prefs.getBool(_ttsEnabledKey) ?? false;
    final sfxEnabled = prefs.getBool(_sfxEnabledKey) ?? true;

    state = Settings(
      themeMode: themeMode,
      locale: locale,
      hostName: hostName,
      hostColor: hostColor,
      ttsEnabled: ttsEnabled,
      sfxEnabled: sfxEnabled,
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

  Future<void> setTtsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ttsEnabledKey, enabled);
    state = state.copyWith(ttsEnabled: enabled);
  }

  Future<void> setSfxEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxEnabledKey, enabled);
    state = state.copyWith(sfxEnabled: enabled);
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
