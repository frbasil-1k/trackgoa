import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings_model.dart';

/// Phase 6.6 — Settings repository backed by SharedPreferences.
///
/// All reads are synchronous (avoids async gaps in the UI). All writes
/// are asynchronous so the UI never blocks.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _kLowBandwidth = 'settings_low_bandwidth';
  static const _kBusArrivalAlerts = 'settings_bus_arrival_alerts';
  static const _kDelayAlerts = 'settings_delay_alerts';
  static const _kPreferredCity = 'settings_preferred_city';
  static const _kThemeMode = 'settings_theme_mode';
  static const _kDemoSimulation = 'settings_demo_simulation';

  /// Returns the current persisted settings synchronously.
  AppSettingsState load() {
    return AppSettingsState(
      lowBandwidthMode: _prefs.getBool(_kLowBandwidth) ?? false,
      busArrivalAlerts: _prefs.getBool(_kBusArrivalAlerts) ?? true,
      delayAlerts: _prefs.getBool(_kDelayAlerts) ?? true,
      preferredCity: _prefs.getString(_kPreferredCity) ?? 'Panaji',
      themeMode: AppThemeMode.fromString(_prefs.getString(_kThemeMode) ?? 'system'),
      demoSimulationEnabled: _prefs.getBool(_kDemoSimulation) ?? true,
    );
  }

  Future<void> _setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  Future<void> _setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  /// Updates low-bandwidth mode.
  Future<AppSettingsState> setLowBandwidth(AppSettingsState current, bool value) async {
    await _setBool(_kLowBandwidth, value);
    return current.copyWith(lowBandwidthMode: value);
  }

  /// Updates bus arrival alerts.
  Future<AppSettingsState> setBusArrivalAlerts(AppSettingsState current, bool value) async {
    await _setBool(_kBusArrivalAlerts, value);
    return current.copyWith(busArrivalAlerts: value);
  }

  /// Updates delay alerts.
  Future<AppSettingsState> setDelayAlerts(AppSettingsState current, bool value) async {
    await _setBool(_kDelayAlerts, value);
    return current.copyWith(delayAlerts: value);
  }

  /// Updates preferred city.
  Future<AppSettingsState> setPreferredCity(AppSettingsState current, String value) async {
    await _setString(_kPreferredCity, value);
    return current.copyWith(preferredCity: value);
  }

  /// Updates theme mode.
  Future<AppSettingsState> setThemeMode(AppSettingsState current, AppThemeMode value) async {
    await _setString(_kThemeMode, value.name);
    return current.copyWith(themeMode: value);
  }

  /// Updates demo simulation toggle.
  Future<AppSettingsState> setDemoSimulation(AppSettingsState current, bool value) async {
    await _setBool(_kDemoSimulation, value);
    return current.copyWith(demoSimulationEnabled: value);
  }

  /// Resets all settings to defaults.
  Future<AppSettingsState> resetToDefaults() async {
    await Future.wait([
      _prefs.setBool(_kLowBandwidth, false),
      _prefs.setBool(_kBusArrivalAlerts, true),
      _prefs.setBool(_kDelayAlerts, true),
      _prefs.setString(_kPreferredCity, 'Panaji'),
      _prefs.setString(_kThemeMode, 'system'),
      _prefs.setBool(_kDemoSimulation, true),
    ]);
    return AppSettingsState.defaults;
  }
}
