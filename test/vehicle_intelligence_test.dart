import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_go/app.dart';
import 'package:smart_go/core/router/app_router.dart';
import 'package:smart_go/core/router/route_paths.dart';
import 'package:smart_go/data/repositories/repository_providers.dart';

void main() {
  group('Batch 3 — Passenger Vehicle Intelligence & Fleet Insight', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      appRouter.go(RoutePaths.home);
    });

    testWidgets(
        'Passenger can view live vehicle registration, occupancy, speed, and amenity intelligence sheet',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const SmartGoApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Navigate from Home into Tracking for Panaji Bus Stand (R1)
      await tester.tap(find.text('Panaji Bus Stand → Panaji Bus Stand').first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Verify route tracking is active
      expect(find.text('Panaji Bus Stand → Panaji Bus Stand'), findsAtLeastNWidgets(1));

      // 2. Verify passenger vehicle intelligence in LiveEtaCard
      // Verified KTCL registration GA-08-V-4965, DEMO badge, and vehicle type should be displayed
      expect(find.text('GA-08-V-4965'), findsOneWidget);
      expect(find.text('DEMO'), findsOneWidget);
      expect(find.text('Electric AC City Shuttle'), findsOneWidget);

      // 3. Tap the vehicle avatar button to open VehicleDetailSheet
      final avatarBtn = find.byKey(const ValueKey('live-eta-bus-avatar-button'));
      expect(avatarBtn, findsOneWidget);
      await tester.tap(avatarBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // 4. Verify VehicleDetailSheet contents
      // Header: Registration plate and VERIFIED FLEET ASSET badge
      expect(find.text('GA-08-V-4965'), findsAtLeastNWidgets(1));
      expect(find.text('VERIFIED FLEET ASSET'), findsOneWidget);
      expect(find.text('Kadamba EV Shuttle #1'), findsOneWidget);

      // Clear simulation disclosure to protect passenger trust
      expect(find.text('Simulated Live Telemetry • Demo Mode'), findsOneWidget);

      // Occupancy metric (estimated / simulated)
      expect(find.text('Occupancy'), findsOneWidget);
      expect(find.text('Many seats available'), findsOneWidget);

      // Current Speed metric (explicitly simulated)
      expect(find.text('Speed'), findsOneWidget);
      expect(find.text('Simulated'), findsAtLeastNWidgets(1));

      // Simulated ETA in next stop card
      expect(find.textContaining('Simulated ETA'), findsOneWidget);

      // Verified Vehicle Specifications header and confidence badge
      expect(find.text('Verified Fleet Specifications'), findsOneWidget);
      expect(find.text('CONFIDENCE A'), findsOneWidget);
      expect(find.textContaining('Olectra K9'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Kadamba Transport Corporation'), findsAtLeastNWidgets(1));

      // Verified capabilities / amenities chips
      expect(find.text('100% Electric (BYD K9 Chassis)'), findsOneWidget);
      expect(find.text('Climate Controlled (AC)'), findsOneWidget);
      expect(find.text('Accessible / Low-Floor'), findsOneWidget);
      expect(find.text('32 Passenger Seats'), findsOneWidget);

      // Action button: "Done"
      expect(find.text('Done'), findsOneWidget);

      // 5. Dismiss sheet with "Done"
      await tester.tap(find.text('Done'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Sheet is dismissed, back to tracking screen
      expect(find.text('Simulated Live Telemetry • Demo Mode'), findsNothing);

      // 6. Test opening sheet via the "Live" vehicle sheet button on the right
      final vehicleSheetBtn = find.byKey(const ValueKey('live-eta-vehicle-sheet-button'));
      expect(vehicleSheetBtn, findsOneWidget);
      await tester.tap(vehicleSheetBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Simulated Live Telemetry • Demo Mode'), findsOneWidget);

      // Close via close icon button
      final closeBtn = find.byKey(const ValueKey('vehicle-detail-close-btn'));
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Simulated Live Telemetry • Demo Mode'), findsNothing);
    });

    testWidgets(
        'Tapping live vehicle marker on map opens vehicle intelligence sheet',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const SmartGoApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to tracking
      await tester.tap(find.text('Panaji Bus Stand → Panaji Bus Stand').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));

      // Find bus marker widget on map for R1-bus-1
      final busMarkerFinder = find.byKey(const ValueKey('bus-marker-R1-bus-1'));
      expect(busMarkerFinder, findsOneWidget);

      // Tap the vehicle marker directly on the map
      await tester.tap(busMarkerFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify vehicle intelligence sheet opened
      expect(find.text('GA-08-V-4965'), findsAtLeastNWidgets(1));
      expect(find.text('Simulated Live Telemetry • Demo Mode'), findsOneWidget);

      // Tap Focus on Map
      await tester.tap(find.text('Focus on Map'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Sheet dismissed after focus
      expect(find.text('Simulated Live Telemetry • Demo Mode'), findsNothing);
    });
  });
}
