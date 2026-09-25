import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_go/data/models/app_settings_model.dart';
import 'package:smart_go/data/repositories/repository_providers.dart';
import 'package:smart_go/data/repositories/settings_repository.dart';
import 'package:smart_go/features/settings/screens/settings_screen.dart';

void main() {
  group('Phase 8 & 9 — Settings Audit & Persistence', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('SettingsRepository persists and reloads all settings', () async {
      final repo = SettingsRepository(prefs);
      final initial = repo.load();

      expect(initial.preferredCity, 'Panaji');
      expect(initial.busArrivalAlerts, true);
      expect(initial.delayAlerts, true);
      expect(initial.lowBandwidthMode, false);
      expect(initial.demoSimulationEnabled, true);
      expect(initial.vibrationEnabled, true);
      expect(initial.distanceUnit, DistanceUnit.kilometers);
      expect(initial.themeMode, AppThemeMode.system);

      // Mutate settings
      var updated = await repo.setPreferredCity(initial, 'Margao');
      updated = await repo.setBusArrivalAlerts(updated, false);
      updated = await repo.setDelayAlerts(updated, false);
      updated = await repo.setLowBandwidth(updated, true);
      updated = await repo.setDemoSimulation(updated, false);
      updated = await repo.setVibration(updated, false);
      updated = await repo.setDistanceUnit(updated, DistanceUnit.miles);
      updated = await repo.setThemeMode(updated, AppThemeMode.dark);

      // Verify immediate state
      expect(updated.preferredCity, 'Margao');
      expect(updated.busArrivalAlerts, false);
      expect(updated.delayAlerts, false);
      expect(updated.lowBandwidthMode, true);
      expect(updated.demoSimulationEnabled, false);
      expect(updated.vibrationEnabled, false);
      expect(updated.distanceUnit, DistanceUnit.miles);
      expect(updated.themeMode, AppThemeMode.dark);

      // Create new repo instance to verify disk persistence
      final reloadedRepo = SettingsRepository(prefs);
      final reloaded = reloadedRepo.load();

      expect(reloaded.preferredCity, 'Margao');
      expect(reloaded.busArrivalAlerts, false);
      expect(reloaded.delayAlerts, false);
      expect(reloaded.lowBandwidthMode, true);
      expect(reloaded.demoSimulationEnabled, false);
      expect(reloaded.vibrationEnabled, false);
      expect(reloaded.distanceUnit, DistanceUnit.miles);
      expect(reloaded.themeMode, AppThemeMode.dark);

      // Reset to defaults
      final reset = await reloadedRepo.resetToDefaults();
      expect(reset.preferredCity, 'Panaji');
      expect(reset.busArrivalAlerts, true);
      expect(reset.delayAlerts, true);
      expect(reset.lowBandwidthMode, false);
      expect(reset.demoSimulationEnabled, true);
      expect(reset.vibrationEnabled, true);
      expect(reset.distanceUnit, DistanceUnit.kilometers);
      expect(reset.themeMode, AppThemeMode.system);
    });

    testWidgets('SettingsScreen displays all logical groups and controls',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Section Headers
      expect(find.text('Preferences'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Performance'), findsOneWidget);
      expect(find.text('Data & Transparency'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);

      // Verify Preference items
      expect(find.text('Default City'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Distance Units'), findsOneWidget);

      // Verify Alert items
      expect(find.text('Bus Arrival Alerts'), findsOneWidget);
      expect(find.text('Delay & Disruption Alerts'), findsOneWidget);
      expect(find.text('Vibrate on Arrival'), findsOneWidget);

      // Verify Performance items
      expect(find.text('Low Bandwidth Mode'), findsOneWidget);
      expect(find.text('Live Telemetry Simulation'), findsOneWidget);

      // Verify Attribution and About
      expect(find.text('Transit Data & Attribution'), findsOneWidget);
      expect(find.text('Data Provenance'), findsOneWidget);
      expect(find.text('SMART-GO'), findsOneWidget);

      // Test Attribution dialog
      await tester.tap(find.text('Transit Data & Attribution'));
      await tester.pumpAndSettle();
      expect(find.text('Department of Transport, Government of Goa & Kadamba Transport Corporation Limited (KTCL).'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Test Reset button
      final resetBtn = find.byKey(const ValueKey('reset-settings-button'));
      expect(resetBtn, findsOneWidget);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();
      expect(find.text('Reset Settings'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });
  });
}
