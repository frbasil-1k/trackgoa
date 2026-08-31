import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackgoa/app.dart';

void main() {
  testWidgets('shell navigation switches destinations', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TrackGoaApp()));
    await tester.pumpAndSettle();

    expect(find.text('TrackGoa'), findsOneWidget);

    await tester.tap(find.text('Routes'));
    await tester.pumpAndSettle();
    expect(find.text('All routes'), findsOneWidget);

    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Saved routes will appear here.'), findsOneWidget);

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
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify tracking screen loaded by checking for route info in bottom sheet
    expect(find.text('Panaji → Miramar'), findsAtLeastNWidgets(1));
    expect(find.text('Estimated Travel Time'), findsOneWidget);

    // Test analytics navigation from bottom sheet
    await tester.ensureVisible(find.text('Analytics'));
    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();
    expect(find.text('Analytics R1'), findsOneWidget);
  });
}
