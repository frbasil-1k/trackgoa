import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_go/features/tracking/services/vehicle_journey_path_service.dart';

void main() {
  group('VehicleJourneyPathService — Selected Vehicle Journey & Directional Segments', () {
    const service = VehicleJourneyPathService();

    final testPolyline = [
      const LatLng(15.2993, 73.9856), // Margao KTC
      const LatLng(15.3100, 73.9800), // Stop 1
      const LatLng(15.3300, 73.9700), // Nuvem
      const LatLng(15.3600, 73.9500), // Thana
      const LatLng(15.4000, 73.9000), // Cortalim
      const LatLng(15.4500, 73.8500), // Agacaim
      const LatLng(15.4963, 73.8364), // Panaji KTC
    ];

    test('Linear corridor: partitions passed, active journey, and remaining segments correctly', () {
      final busAtNuvem = const LatLng(15.3300, 73.9700);
      final destAtCortalim = const LatLng(15.4000, 73.9000);

      final segments = service.computeJourneySegments(
        routePolyline: testPolyline,
        busLocation: busAtNuvem,
        destinationLocation: destAtCortalim,
        isLoopRoute: false,
        chevronSpacingMeters: 500.0,
      );

      // Passed points should lead up to Nuvem
      expect(segments.passedPolyline.isNotEmpty, isTrue);
      expect(segments.passedPolyline.first, equals(testPolyline.first));
      expect(segments.passedPolyline.last, equals(busAtNuvem));

      // Active journey starts at the bus and ends at Cortalim
      expect(segments.activeJourneyPolyline.isNotEmpty, isTrue);
      expect(segments.activeJourneyPolyline.first, equals(busAtNuvem));
      expect(segments.activeJourneyPolyline.last, equals(destAtCortalim));

      // Remaining points start at Cortalim and end at Panaji
      expect(segments.remainingPolyline.isNotEmpty, isTrue);
      expect(segments.remainingPolyline.first, equals(destAtCortalim));
      expect(segments.remainingPolyline.last, equals(testPolyline.last));

      // Directional cues should exist along the active journey
      expect(segments.directionalCues.isNotEmpty, isTrue);
      for (final cue in segments.directionalCues) {
        expect(cue.bearingDegrees, inInclusiveRange(0.0, 360.0));
      }
    });

    test('Linear corridor: handles bus having already passed destination', () {
      final busAtAgacaim = const LatLng(15.4500, 73.8500);
      final destAtNuvem = const LatLng(15.3300, 73.9700); // Behind the bus

      final segments = service.computeJourneySegments(
        routePolyline: testPolyline,
        busLocation: busAtAgacaim,
        destinationLocation: destAtNuvem,
        isLoopRoute: false,
      );

      // Passed points lead up to Agacaim
      expect(segments.passedPolyline.last, equals(busAtAgacaim));

      // Active journey starts at Agacaim and continues to terminus (Panaji)
      expect(segments.activeJourneyPolyline.first, equals(busAtAgacaim));
      expect(segments.activeJourneyPolyline.last, equals(testPolyline.last));

      // Remaining points beyond destination is empty because destination was passed
      expect(segments.remainingPolyline.isEmpty, isTrue);
    });

    test('Loop route: wraps active journey across loop boundary when destination is on next lap', () {
      final loopPolyline = [
        const LatLng(15.4963, 73.8364), // Panaji Bus Stand (Origin & Terminus)
        const LatLng(15.4900, 73.8200), // Taleigao
        const LatLng(15.4600, 73.8000), // Dona Paula
        const LatLng(15.4800, 73.8100), // Caranzalem
        const LatLng(15.4963, 73.8364), // Panaji Bus Stand (Loop close)
      ];

      final busAtCaranzalem = const LatLng(15.4800, 73.8100);
      final destAtTaleigao = const LatLng(15.4900, 73.8200); // Behind on index, but upcoming on loop!

      final segments = service.computeJourneySegments(
        routePolyline: loopPolyline,
        busLocation: busAtCaranzalem,
        destinationLocation: destAtTaleigao,
        isLoopRoute: true,
      );

      // Active journey starts at bus
      expect(segments.activeJourneyPolyline.first, equals(busAtCaranzalem));
      // And reaches destination on the loop
      expect(segments.activeJourneyPolyline.last, equals(destAtTaleigao));
    });

    test('Null bus location falls back gracefully to full route as active path', () {
      final segments = service.computeJourneySegments(
        routePolyline: testPolyline,
        busLocation: null,
        destinationLocation: null,
        isLoopRoute: false,
      );

      expect(segments.basePolyline, equals(testPolyline));
      expect(segments.activeJourneyPolyline, equals(testPolyline));
      expect(segments.passedPolyline.isEmpty, isTrue);
    });

    test('Midway interpolated bus position connects seamlessly with zero gap and zero bifurcation', () {
      // Bus is between Stop 1 and Nuvem (interpolated point not present in testPolyline)
      const midwayBus = LatLng(15.3200, 73.9750);
      const destAtPanaji = LatLng(15.4963, 73.8364);

      final segments = service.computeJourneySegments(
        routePolyline: testPolyline,
        busLocation: midwayBus,
        destinationLocation: destAtPanaji,
        isLoopRoute: false,
      );

      // Passed ends at midwayBus
      expect(segments.passedPolyline.last, equals(midwayBus));
      // Active starts at midwayBus
      expect(segments.activeJourneyPolyline.first, equals(midwayBus));
      // Seamless connection: passed.last == active.first
      expect(segments.passedPolyline.last, equals(segments.activeJourneyPolyline.first));
    });
  });
}
