import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackgoa/app.dart';
import 'package:trackgoa/data/repositories/repository_providers.dart';

void main() {
  testWidgets('shell navigation switches destinations', (tester) async {
    // Phase 6.5 — Mock SharedPreferences for widget tests.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const TrackGoaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TrackGoa'), findsOneWidget);

    await tester.tap(find.text('Routes'));
    await tester.pumpAndSettle();
    expect(find.text('All routes'), findsOneWidget);

    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(find.text('No saved routes yet'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(
      find.text('Settings will be available in a later phase.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    // Navigate to tracking screen (now has full map implementation)
    await tester.tap(find.text('Panaji → Miramar'));
    // Use pump (not pumpAndSettle) — the bus animation ticker runs every
    // frame so the screen never settles.
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    // Verify tracking screen loaded by checking for route info in bottom sheet
    expect(find.text('Panaji → Miramar'), findsAtLeastNWidgets(1));
    // Live ETA card is now shown with a 'Live' status pill
    expect(find.text('Live'), findsOneWidget);

    // Find analytics button and test navigation
    await tester.drag(find.byType(ListView).last, const Offset(0, -200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Analytics'), findsOneWidget);
    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();
    expect(find.text('Analytics R1'), findsOneWidget);
  });
}
