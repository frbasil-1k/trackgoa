import 'package:flutter_test/flutter_test.dart';
import 'package:trackgoa/app.dart';

void main() {
  testWidgets('shell navigation switches destinations', (tester) async {
    await tester.pumpWidget(const TrackGoaApp());
    await tester.pumpAndSettle();

    expect(find.text('Your journey, in view.'), findsOneWidget);

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
    await tester.tap(find.text('Open route tracking'));
    await tester.pumpAndSettle();
    expect(find.text('Tracking R1'), findsOneWidget);

    await tester.tap(find.text('View route analytics'));
    await tester.pumpAndSettle();
    expect(find.text('Analytics R1'), findsOneWidget);
  });
}
