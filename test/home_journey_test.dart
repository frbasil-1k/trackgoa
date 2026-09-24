import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_go/app.dart';
import 'package:smart_go/data/repositories/repository_providers.dart';

void main() {
  group('Batch 1 — Passenger Discovery & Search Journey', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('Complete discovery flow: header, city filter, stop search, and tracking entry',
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
          child: const SmartGoApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify deployment branding on Home header
      expect(find.text('SMART-GO'), findsOneWidget);
      expect(find.text('Navigate Goa, effortlessly.'), findsOneWidget);
      expect(find.text('Goa'), findsOneWidget);

      // 2. Verify authentic featured live routes are visible
      expect(find.text('Panaji Bus Stand → Panaji Bus Stand'), findsAtLeastNWidgets(1));
      expect(find.text('Margao KTC Bus Stand → Panaji KTC Bus Stand'), findsOneWidget);
      expect(find.text('Vasco KTC Bus Stand → Panaji KTC Bus Stand'), findsOneWidget);

      // 3. Test City Filtering: Tap 'Margao' chip
      await tester.tap(find.text('Margao').first);
      await tester.pumpAndSettle();

      // In Margao: Margao KTC Bus Stand → Panaji KTC Bus Stand (MRG1) should be visible
      expect(find.text('Margao KTC Bus Stand → Panaji KTC Bus Stand'), findsOneWidget);
      expect(find.text('Panaji Bus Stand → Panaji Bus Stand'), findsNothing);
      expect(find.text('Vasco KTC Bus Stand → Panaji KTC Bus Stand'), findsNothing);

      // Tap 'Vasco' chip
      await tester.tap(find.text('Vasco').first);
      await tester.pumpAndSettle();

      // In Vasco: only Vasco KTC Bus Stand → Panaji KTC Bus Stand (MRG11) should be visible
      expect(find.text('Vasco KTC Bus Stand → Panaji KTC Bus Stand'), findsOneWidget);
      expect(find.text('Margao KTC Bus Stand → Panaji KTC Bus Stand'), findsNothing);
      expect(find.text('Panaji Bus Stand → Panaji Bus Stand'), findsNothing);

      // Tap 'All' chip to reset city filter
      await tester.tap(find.text('All').first);
      await tester.pumpAndSettle();
      expect(find.text('Panaji Bus Stand → Panaji Bus Stand'), findsAtLeastNWidgets(1));
      expect(find.text('Margao KTC Bus Stand → Panaji KTC Bus Stand'), findsOneWidget);
      expect(find.text('Vasco KTC Bus Stand → Panaji KTC Bus Stand'), findsOneWidget);

      // 4. Test Search: Activate search and search for intermediate stop 'Kala Academy'
      await tester.tap(find.byKey(const ValueKey('home-search-inactive')));
      await tester.pumpAndSettle();

      // Enter query 'Kala Academy'
      await tester.enterText(
        find.byKey(const ValueKey('home-search-active')),
        'Kala Academy',
      );
      await tester.pumpAndSettle();

      // R1 passes through Kala Academy: R1 is shown with 'Passes Kala Academy A' badge
      expect(find.text('Panaji Bus Stand → Panaji Bus Stand'), findsAtLeastNWidgets(1));
      expect(find.text('Passes Kala Academy A'), findsAtLeastNWidgets(1));
      expect(find.text('Margao KTC Bus Stand → Panaji KTC Bus Stand'), findsNothing);
      expect(find.text('Vasco KTC Bus Stand → Panaji KTC Bus Stand'), findsNothing);

      // Search for stop 'Dabolim'
      await tester.enterText(
        find.byKey(const ValueKey('home-search-active')),
        'Dabolim',
      );
      await tester.pumpAndSettle();

      // MRG11 passes through Dabolim
      expect(find.text('Vasco KTC Bus Stand → Panaji KTC Bus Stand'), findsOneWidget);
      expect(find.text('Passes Dabolim'), findsOneWidget);
      expect(find.text('Panaji Bus Stand → Panaji Bus Stand'), findsNothing);

      // Search for non-existent place
      await tester.enterText(
        find.byKey(const ValueKey('home-search-active')),
        'Atlantis',
      );
      await tester.pumpAndSettle();

      expect(find.text('No matches found'), findsOneWidget);
      expect(find.text('Show all routes'), findsOneWidget);

      // Tap 'Show all routes'
      await tester.tap(find.text('Show all routes'));
      await tester.pumpAndSettle();

      // All routes restored
      expect(find.text('Panaji Bus Stand → Panaji Bus Stand'), findsAtLeastNWidgets(1));
      expect(find.text('Margao KTC Bus Stand → Panaji KTC Bus Stand'), findsOneWidget);
      expect(find.text('Vasco KTC Bus Stand → Panaji KTC Bus Stand'), findsOneWidget);

      // 5. Test Transition into Tracking
      await tester.tap(find.text('Panaji Bus Stand → Panaji Bus Stand').first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      // Tracking screen active with live route bottom sheet
      expect(find.text('Panaji Bus Stand → Panaji Bus Stand'), findsAtLeastNWidgets(1));
      expect(find.text('Live'), findsOneWidget);
    });
  });
}
