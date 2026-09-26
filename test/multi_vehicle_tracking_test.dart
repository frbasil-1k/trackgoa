import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_go/app.dart';
import 'package:smart_go/core/router/app_router.dart';
import 'package:smart_go/core/router/route_paths.dart';
import 'package:smart_go/data/repositories/repository_providers.dart';

void main() {
  group('SMART-GO — Multi-Vehicle Tracking & Vehicle-Centric Journey Context', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      appRouter.go(RoutePaths.home);
    });

    testWidgets(
        'Route MRG1 shows multiple vehicles and switches complete journey context on 1-tap',
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

      // 1. Search for and navigate into Route MRG1 (Margao → Panaji via Cortalim)
      expect(find.textContaining('Margao KTC Bus Stand → Panaji KTC Bus Stand'), findsAtLeastNWidgets(1));
      await tester.tap(find.textContaining('Margao KTC Bus Stand → Panaji KTC Bus Stand').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));

      // 2. Verify Multi-Vehicle Selector is visible with both buses
      expect(find.textContaining('2 BUSES ON THIS ROUTE'), findsOneWidget);
      expect(find.text('GA-08-V-5072'), findsAtLeastNWidgets(1));
      expect(find.text('GA-08-V-4965'), findsAtLeastNWidgets(1));

      // By default, first bus GA-08-V-5072 is tracking
      expect(find.text('TRACKING'), findsOneWidget);

      // Verify destination banner is visible
      expect(find.textContaining('DESTINATION: Panaji KTC Bus Stand'), findsOneWidget);

      // 3. Switch to Vehicle 2 (GA-08-V-4965) with 1 tap in the selector
      final bus2Selector = find.byKey(const ValueKey('vehicle-selector-MRG1-bus-2'));
      expect(bus2Selector, findsOneWidget);
      await tester.tap(bus2Selector);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify feedback snackbar confirming switch
      expect(find.textContaining('Tracking switched to GA-08-V-4965'), findsOneWidget);

      // 4. Verify that Vehicle 2 is now the active source of truth
      // Now GA-08-V-4965 has the 'TRACKING' badge
      expect(find.text('TRACKING'), findsOneWidget);

      // 5. Open VehicleDetailSheet for the active vehicle
      final avatarBtn = find.byKey(const ValueKey('live-eta-bus-avatar-button'));
      expect(avatarBtn, findsOneWidget);
      await tester.tap(avatarBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify VehicleDetailSheet displays Vehicle 2's verified registration GA-08-V-4965
      expect(find.text('GA-08-V-4965'), findsAtLeastNWidgets(1));
      expect(find.text('Kadamba Regional #2'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Close sheet
      await tester.tap(find.text('Done'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Dismiss snackbars
      ScaffoldMessenger.of(tester.element(find.byKey(const ValueKey('live-eta-bus-avatar-button')))).clearSnackBars();
      await tester.pump(const Duration(milliseconds: 200));

      // 6. Switch back to Vehicle 1 (MRG1-bus-1)
      final bus1Selector = find.byKey(const ValueKey('vehicle-selector-MRG1-bus-1'));
      expect(bus1Selector, findsOneWidget);
      await tester.tap(bus1Selector);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Confirmation snackbar for Vehicle 1
      expect(find.textContaining('Tracking switched to GA-08-V-5072'), findsOneWidget);

      // Dismiss snackbars
      ScaffoldMessenger.of(tester.element(find.byKey(const ValueKey('live-eta-bus-avatar-button')))).clearSnackBars();
      await tester.pump(const Duration(milliseconds: 200));

      // 7. Test vehicle-centric stop timeline:
      await tester.drag(find.byKey(const ValueKey('tracking-bottom-sheet-list')), const Offset(0, -350));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify route stops are visible
      expect(find.text('Route Stops'), findsOneWidget);
    });

    testWidgets('Tapping secondary vehicle marker on map switches tracking context',
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

      // Navigate to tracking for Route R1
      await tester.tap(find.text('Panaji Bus Stand → Panaji Bus Stand').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));

      // Both R1-bus-1 and R1-bus-2 markers are present on the map
      final bus1Finder = find.byKey(const ValueKey('bus-marker-R1-bus-1'));
      final bus2Finder = find.byKey(const ValueKey('bus-marker-R1-bus-2'));
      expect(bus1Finder, findsOneWidget);
      expect(bus2Finder, findsOneWidget);

      // Pan map slightly so the southern vehicle marker is in the open map area above bottom sheet
      await tester.drag(find.byType(FlutterMap), const Offset(0, -250));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap the secondary bus marker (R1-bus-2)
      await tester.tap(bus2Finder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tracking should now be switched to R1-bus-2 (GA-08-V-4980)
      expect(find.textContaining('Tracking switched to GA-08-V-4980'), findsOneWidget);
    });
  });
}
