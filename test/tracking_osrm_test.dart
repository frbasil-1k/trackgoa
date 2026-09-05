import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trackgoa/core/utils/polyline_simplifier.dart';
import 'package:trackgoa/data/mock/mock_routes.dart';
import 'package:trackgoa/features/tracking/services/polyline_navigation_service.dart';

void main() {
  group('OSRM Real Road Geometry Foundation', () {
    test('all mock routes contain authentic road-following coordinates (>80 points)', () {
      expect(mockRoutes.length, 3);

      final r1 = mockRoutes.firstWhere((r) => r.id == 'r1');
      final r2 = mockRoutes.firstWhere((r) => r.id == 'r2');
      final r3 = mockRoutes.firstWhere((r) => r.id == 'r3');

      // Check coordinate counts match OSRM generation
      expect(r1.polylinePoints.length, greaterThanOrEqualTo(80));
      expect(r1.polylinePoints.length, 163);

      expect(r2.polylinePoints.length, greaterThanOrEqualTo(80));
      expect(r2.polylinePoints.length, 106);

      expect(r3.polylinePoints.length, greaterThanOrEqualTo(80));
      expect(r3.polylinePoints.length, 335);
    });

    test('first and last coordinates align with route origin and destination stops', () {
      for (final route in mockRoutes) {
        final firstStop = route.stops.first.coordinates;
        final lastStop = route.stops.last.coordinates;

        final firstPoly = route.polylinePoints.first;
        final lastPoly = route.polylinePoints.last;

        // Origin/destination stops and polyline endpoints within ~250 meters
        // (OSRM routing may start/end slightly offset from exact stop coordinates)
        const nav = PolylineNavigationService();
        final startDist = nav.calculateDistance(firstStop, firstPoly);
        final endDist = nav.calculateDistance(lastStop, lastPoly);

        expect(startDist, lessThan(250));
        expect(endDist, lessThan(250));
      }
    });
  });

  group('PolylineNavigationService (Phase 6 Foundation)', () {
    const nav = PolylineNavigationService();

    test('calculateBearing returns valid angles in 0-360 range', () {
      const p1 = LatLng(15.4989, 73.8278);
      const p2 = LatLng(15.4972, 73.8264);

      final bearing = nav.calculateBearing(p1, p2);
      expect(bearing, greaterThanOrEqualTo(0.0));
      expect(bearing, lessThan(360.0));
    });

    test('calculatePolylineLength computes realistic road distances in meters', () {
      final r1 = mockRoutes.firstWhere((r) => r.id == 'r1');
      final lengthMeters = nav.calculatePolylineLength(r1.polylinePoints);

      // Panaji to Miramar is approx 4.0 - 5.5 km along actual road network
      expect(lengthMeters, greaterThan(3500));
      expect(lengthMeters, lessThan(6500));
    });

    test('interpolateAlongPolyline returns continuous coordinates and valid heading', () {
      final r1 = mockRoutes.firstWhere((r) => r.id == 'r1');
      final totalLength = nav.calculatePolylineLength(r1.polylinePoints);

      // Interpolate halfway
      final halfway = nav.interpolateAlongPolyline(r1.polylinePoints, totalLength / 2);
      expect(halfway, isNotNull);
      expect(halfway!.bearing, greaterThanOrEqualTo(0.0));
      expect(halfway.bearing, lessThan(360.0));
      expect(halfway.position.latitude, inInclusiveRange(15.48, 15.51));
      expect(halfway.position.longitude, inInclusiveRange(73.80, 73.83));
    });
  });

  group('PolylineSimplifier (Phase 5.11 / Phase 5.6)', () {
    test('simplify preserves start and end points', () {
      final r1 = mockRoutes.firstWhere((r) => r.id == 'r1');
      final original = r1.polylinePoints;
      final simplified = PolylineSimplifier.simplify(original, epsilon: 2.5);

      expect(simplified.first, original.first);
      expect(simplified.last, original.last);
    });

    test('simplified polylines with 2.5m epsilon preserve authentic road geometry curves', () {
      final r1 = mockRoutes.firstWhere((r) => r.id == 'r1');
      final original = r1.polylinePoints;
      final simplified = PolylineSimplifier.simplify(original, epsilon: 2.5);

      // 2.5m tolerance preserves rich curves (keeps between 70 and 120 points from 163)
      expect(simplified.length, greaterThanOrEqualTo(60));
      expect(simplified.length, lessThanOrEqualTo(130));
      expect(simplified.first, original.first);
      expect(simplified.last, original.last);
    });

    test('simplified polylines have fewer points than originals across all routes', () {
      for (final route in mockRoutes) {
        final original = route.polylinePoints;
        final simplified = PolylineSimplifier.simplify(original, epsilon: 2.5);

        expect(simplified.length, lessThan(original.length));
        expect(simplified.length, greaterThan(2)); // Must NEVER be flattened to a straight line
      }
    });

    test('simplification with very small epsilon keeps most points', () {
      final r1 = mockRoutes.firstWhere((r) => r.id == 'r1');
      final original = r1.polylinePoints;
      final simplified = PolylineSimplifier.simplify(original, epsilon: 0.1);

      // With very small epsilon (0.1m), should keep most points (>75%)
      expect(simplified.length, greaterThan(original.length * 0.75));
      expect(simplified.first, original.first);
      expect(simplified.last, original.last);
    });

    test('simplification with large epsilon returns only endpoints', () {
      final r1 = mockRoutes.firstWhere((r) => r.id == 'r1');
      final original = r1.polylinePoints;
      final simplified = PolylineSimplifier.simplify(original, epsilon: 1000.0);

      // With very large epsilon, all intermediate points are within tolerance
      expect(simplified.length, equals(2));
      expect(simplified.first, original.first);
      expect(simplified.last, original.last);
    });

    test('simplified polyline maintains route shape and connectivity', () {
      const nav = PolylineNavigationService();
      final r1 = mockRoutes.firstWhere((r) => r.id == 'r1');

      final original = r1.polylinePoints;
      final simplified = PolylineSimplifier.simplify(original, epsilon: 8.0);

      // Verify simplified polyline is connected (no unreasonable gaps)
      for (int i = 0; i < simplified.length - 1; i++) {
        final dist = nav.calculateDistance(simplified[i], simplified[i + 1]);
        // No segment should be longer than 1km (ensures reasonable connectivity)
        expect(dist, lessThan(1000.0));
      }

      // Verify total path length is reasonably similar
      final originalLength = nav.calculatePolylineLength(original);
      final simplifiedLength = nav.calculatePolylineLength(simplified);

      // Simplified should be within 20% of original length
      expect(simplifiedLength, greaterThan(originalLength * 0.8));
      expect(simplifiedLength, lessThan(originalLength * 1.2));
    });

    test('handles edge case of 2-point polyline', () {
      final twoPoints = [
        const LatLng(15.4989, 73.8278),
        const LatLng(15.4972, 73.8264),
      ];
      final simplified = PolylineSimplifier.simplify(twoPoints, epsilon: 8.0);

      expect(simplified.length, equals(2));
      expect(simplified, equals(twoPoints));
    });

    test('handles edge case of single-point polyline', () {
      final onePoint = [const LatLng(15.4989, 73.8278)];
      final simplified = PolylineSimplifier.simplify(onePoint, epsilon: 8.0);

      expect(simplified.length, equals(1));
      expect(simplified, equals(onePoint));
    });
  });
}
