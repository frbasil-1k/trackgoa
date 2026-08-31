import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
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
}
