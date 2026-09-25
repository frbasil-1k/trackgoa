import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_go/app.dart';
import 'package:smart_go/core/router/app_router.dart';
import 'package:smart_go/core/router/route_paths.dart';
import 'package:smart_go/data/repositories/repository_providers.dart';

void main() {
  group('Batch 2 — Passenger Tracking, Destination & Alerts Journey', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      appRouter.go(RoutePaths.home);
    });

    testWidgets(
        'Interactive destination targeting, stop arrival alerts arm/disarm, and trip sharing',
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

      // Verify route header and live indicator are displayed
      expect(find.text('Panaji Bus Stand → Panaji Bus Stand'), findsAtLeastNWidgets(1));
      expect(find.text('Live'), findsOneWidget);

      // Verify default destination card is shown
      expect(find.textContaining('DESTINATION: Panaji Bus Stand'), findsOneWidget);

      // 2. Scroll bottom sheet to reveal action buttons
      await tester.drag(find.byKey(const ValueKey('tracking-bottom-sheet-list')), const Offset(0, -200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 3. Test Arming Stop Arrival Alert
      expect(find.text('Get Alerts'), findsOneWidget);
      await tester.tap(find.text('Get Alerts'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Alert button transitions to 'Alerts Active' with feedback
      expect(find.text('Alerts Active'), findsOneWidget);

      // Disarm alerts
      await tester.tap(find.text('Alerts Active'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Get Alerts'), findsOneWidget);
      expect(
        find.textContaining('Stop alerts turned off'),
        findsOneWidget,
      );

      // Dismiss snackbars so share action shows cleanly
      ScaffoldMessenger.of(tester.element(find.text('Panaji Bus Stand → Panaji Bus Stand').first)).clearSnackBars();
      await tester.pump(const Duration(milliseconds: 300));

      // 4. Test Share Trip action
      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.share_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Trip summary copied to clipboard!'), findsOneWidget);

      // Dismiss snackbars so they do not obstruct touch targets
      ScaffoldMessenger.of(tester.element(find.text('Panaji Bus Stand → Panaji Bus Stand').first)).clearSnackBars();
      await tester.pump(const Duration(milliseconds: 300));

      // 5. Scroll further to stops timeline until 'Kala Academy A' is visible
      await tester.drag(find.byKey(const ValueKey('tracking-bottom-sheet-list')), const Offset(0, -500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify timeline stop 'Kala Academy A' is visible
      expect(find.text('Kala Academy A'), findsOneWidget);

      // 6. Test Interactive Stop Targeting: Tap intermediate stop 'Kala Academy A'
      await tester.tap(find.text('Kala Academy A'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Target should now be 'Kala Academy A' with "Your Stop" badge and confirmation snackbar
      expect(find.text('Your Stop'), findsOneWidget);
      expect(find.textContaining('Destination set: Kala Academy A'), findsOneWidget);

      // Dismiss snackbars
      ScaffoldMessenger.of(tester.element(find.text('Panaji Bus Stand → Panaji Bus Stand').first)).clearSnackBars();
      await tester.pump(const Duration(milliseconds: 300));

      // 7. Test Analytics navigation
      await tester.drag(find.byKey(const ValueKey('tracking-bottom-sheet-list')), const Offset(0, 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Analytics'), findsOneWidget);
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();
      expect(find.text('Analytics R1'), findsOneWidget);
    });

    testWidgets(
        '1-tap sheet toggle and back navigation ergonomics',
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

      // Open tracking
      await tester.tap(find.text('Panaji Bus Stand → Panaji Bus Stand').first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byTooltip('Expand route sheet'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('bottom-sheet-drag-handle')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Now sheet is expanded
      expect(find.byTooltip('Collapse route sheet'), findsOneWidget);

      // Tap again to collapse
      await tester.tap(find.byKey(const ValueKey('bottom-sheet-drag-handle')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byTooltip('Expand route sheet'), findsOneWidget);

      // Test Back navigation via GlassBackButton tooltip
      expect(find.byTooltip('Back to routes'), findsOneWidget);
      await tester.tap(find.byTooltip('Back to routes'));
      await tester.pumpAndSettle();

      // Should be back on Home screen
      expect(find.text('SMART-GO'), findsOneWidget);
    });
  });
}
