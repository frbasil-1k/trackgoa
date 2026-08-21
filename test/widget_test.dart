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
    expect(find.text('Sample Route'), findsOneWidget);

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
    await tester.tap(find.text('Panaji → Miramar'));
    await tester.pumpAndSettle();
    expect(find.text('Tracking R1'), findsOneWidget);

    await tester.tap(find.text('View route analytics'));
    await tester.pumpAndSettle();
    expect(find.text('Analytics R1'), findsOneWidget);
  });
}
