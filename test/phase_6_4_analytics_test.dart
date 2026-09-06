import 'package:flutter_test/flutter_test.dart';
import 'package:trackgoa/data/repositories/analytics_repository.dart';

void main() {
  group('Phase 6.4 — Analytics Repository', () {
    const repo = MockAnalyticsRepository();

    test('returns 3 route bundles', () async {
      final bundles = await repo.getAllAnalytics();
      expect(bundles.length, 3);
    });

    test('R1 has the required Phase 6.4 metrics', () async {
      final bundles = await repo.getAllAnalytics();
      final r1 = bundles.firstWhere((b) => b.routeId == 'r1');
      expect(r1.onTimePercentage, 94);
      expect(r1.averageDelayMinutes, 2);
      expect(r1.reliabilityScore, 96);
      expect(r1.peakPeriod, '5–7 PM');
      expect(r1.origin, 'Panaji');
      expect(r1.destination, 'Miramar');
    });

    test('R2 has Margao–Fatorda metrics', () async {
      final bundles = await repo.getAllAnalytics();
      final r2 = bundles.firstWhere((b) => b.routeId == 'r2');
      expect(r2.onTimePercentage, 88);
      expect(r2.averageDelayMinutes, 4);
      expect(r2.reliabilityScore, 90);
    });

    test('R3 has Vasco–Chicalim metrics', () async {
      final bundles = await repo.getAllAnalytics();
      final r3 = bundles.firstWhere((b) => b.routeId == 'r3');
      expect(r3.onTimePercentage, 91);
      expect(r3.averageDelayMinutes, 3);
      expect(r3.reliabilityScore, 93);
    });

    test('reliability trend has 7 daily points', () async {
      final bundles = await repo.getAllAnalytics();
      for (final b in bundles) {
        expect(b.reliabilityTrend.length, 7);
        for (final p in b.reliabilityTrend) {
          expect(p.value, inInclusiveRange(0, 100));
          expect(p.label.isNotEmpty, isTrue);
        }
      }
    });

    test('getAnalyticsForRoute returns null for unknown id', () async {
      final result = await repo.getAnalyticsForRoute('nope');
      expect(result, isNull);
    });

    test('getAnalyticsForRoute returns bundle for valid id', () async {
      final r1 = await repo.getAnalyticsForRoute('r1');
      expect(r1, isNotNull);
      expect(r1!.routeShortName, 'R1');
    });
  });
}
