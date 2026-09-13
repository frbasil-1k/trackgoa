import 'package:flutter/material.dart';

/// Phase 6.6 — Persisted app settings state.
///
/// Architecture note: all fields are simple values making this trivially
/// serializable to SharedPreferences or a backend. The full app theme and
/// feature flags are always resolved from this state at runtime.
@immutable
class AppSettingsState {
  const AppSettingsState({
    required this.lowBandwidthMode,
    required this.busArrivalAlerts,
    required this.delayAlerts,
    required this.preferredCity,
    required this.themeMode,
    required this.demoSimulationEnabled,
  });

  /// Low-bandwidth mode reduces map tile quality and disables animations.
  final bool lowBandwidthMode;

  /// Enable notifications when a bus approaches a tracked stop.
  final bool busArrivalAlerts;

  /// Enable notifications when a tracked bus is significantly delayed.
  final bool delayAlerts;

  /// The city the user primarily travels in (affects default route filters).
  final String preferredCity;

  /// App-wide theme: system, light, or dark.
  final AppThemeMode themeMode;

  /// When true, bus simulation runs with demo data (Phase 6.1).
  final bool demoSimulationEnabled;

  AppSettingsState copyWith({
    bool? lowBandwidthMode,
    bool? busArrivalAlerts,
    bool? delayAlerts,
    String? preferredCity,
    AppThemeMode? themeMode,
    bool? demoSimulationEnabled,
  }) =>
      AppSettingsState(
        lowBandwidthMode: lowBandwidthMode ?? this.lowBandwidthMode,
        busArrivalAlerts: busArrivalAlerts ?? this.busArrivalAlerts,
        delayAlerts: delayAlerts ?? this.delayAlerts,
        preferredCity: preferredCity ?? this.preferredCity,
        themeMode: themeMode ?? this.themeMode,
        demoSimulationEnabled:
            demoSimulationEnabled ?? this.demoSimulationEnabled,
      );

  /// Default settings for new users or when preferences are reset.
  static const defaults = AppSettingsState(
    lowBandwidthMode: false,
    busArrivalAlerts: true,
    delayAlerts: true,
    preferredCity: 'Panaji',
    themeMode: AppThemeMode.system,
    demoSimulationEnabled: true,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettingsState &&
      other.lowBandwidthMode == lowBandwidthMode &&
      other.busArrivalAlerts == busArrivalAlerts &&
      other.delayAlerts == delayAlerts &&
      other.preferredCity == preferredCity &&
      other.themeMode == themeMode &&
      other.demoSimulationEnabled == demoSimulationEnabled;

  @override
  int get hashCode => Object.hash(
        lowBandwidthMode,
        busArrivalAlerts,
        delayAlerts,
        preferredCity,
        themeMode,
        demoSimulationEnabled,
      );
}

/// App theme mode enum matching Flutter's ThemeMode with a "system" default.
enum AppThemeMode {
  system,
  light,
  dark;

  String get displayName {
    switch (this) {
      case AppThemeMode.system:
        return 'System';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }

  ThemeMode toFlutterThemeMode() {
    switch (this) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  static AppThemeMode fromString(String value) {
    return switch (value) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };
  }
}
