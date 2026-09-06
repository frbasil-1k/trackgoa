import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trackgoa/data/models/bus_position.dart';
import 'package:trackgoa/data/models/route_model.dart';
import 'package:trackgoa/data/models/stop_model.dart';
import 'package:trackgoa/features/tracking/services/eta_calculation_service.dart';

void main() {
  // Synthetic 3-stop route for deterministic testing.
  RouteModel makeRoute() {
    final stops = [
      const StopModel(
        id: 's1',
        name: 'Origin',
        coordinates: LatLng(0.0, 0.0),
        routeId: 'r1',
        order: 0,
      ),
      const StopModel(
        id: 's2',
        name: 'Middle',
        coordinates: LatLng(0.0, 0.001),
        routeId: 'r1',
        order: 1,
      ),
      const StopModel(
        id: 's3',
        name: 'Destination',
        coordinates: LatLng(0.0, 0.002),
        routeId: 'r1',
        order: 2,
      ),
    ];
    final polyline = const [
      LatLng(0.0, 0.0),
      LatLng(0.0, 0.0005),
      LatLng(0.0, 0.001),
      LatLng(0.0, 0.0015),
      LatLng(0.0, 0.002),
    ];
    return RouteModel(
      id: 'r1',
      name: 'R1',
      shortName: 'R1',
      origin: 'A',
      destination: 'B',
      stops: stops,
      polylinePoints: polyline,
      color: const Color(0xFF000000),
      estimatedTravelMinutes: 5,
    );
  }

  BusPosition makeBusAt({
    required LatLng pos,
    double speed = 30.0,
    String? nearestStopId,
    String? nextStopId,
    double? distanceRemainingToNextStopMeters,
  }) {
    return BusPosition(
      busId: 'r1-bus-1',
      coordinates: pos,
      headingDegrees: 90,
      speedKmh: speed,
      timestamp: DateTime.now(),
      nearestStopId: nearestStopId,
      nextStopId: nextStopId,
      distanceRemainingToNextStopMeters: distanceRemainingToNextStopMeters,
    );
  }

  const etaService = EtaCalculationService();

  group('Phase 6.3 — ETA calculation', () {
    test('returns empty list when bus position is null', () {
      final result = etaService.computeStopsProgress(
        route: makeRoute(),
        busPosition: null,
      );
      expect(result, isEmpty);
    });

    test('returns one StopProgress per stop in route order', () {
      final route = makeRoute();
      final bus = makeBusAt(pos: const LatLng(0.0, 0.0), nearestStopId: 's1');

      final result = etaService.computeStopsProgress(
        route: route,
        busPosition: bus,
      );
      expect(result.length, 3);
      expect(result.map((p) => p.stop.id), ['s1', 's2', 's3']);
    });

    test('marks nearest stop as current', () {
      final route = makeRoute();
      final bus = makeBusAt(pos: const LatLng(0.0, 0.001), nearestStopId: 's2');

      final result = etaService.computeStopsProgress(
        route: route,
        busPosition: bus,
      );
      expect(result[0].state, StopProgressState.upcoming);
      expect(result[1].state, StopProgressState.current);
      expect(result[2].state, StopProgressState.upcoming);
    });

    test('computes positive ETA in seconds for upcoming stops', () {
      final route = makeRoute();
      final bus = makeBusAt(
        pos: const LatLng(0.0, 0.0),
        speed: 30.0,
        nearestStopId: 's1',
      );

      final result = etaService.computeStopsProgress(
        route: route,
        busPosition: bus,
      );
      // The bus is at the origin; ETAs to s2 and s3 should be > 0.
      expect(result[1].etaSeconds, greaterThan(0));
      expect(result[2].etaSeconds, greaterThan(0));
    });

    test('etaLabel returns Arriving for sub-30-second ETAs', () {
      expect(
        const StopProgress(
          stop: StopModel(
            id: 'x',
            name: 'X',
            coordinates: LatLng(0, 0),
            routeId: 'r',
            order: 0,
          ),
          state: StopProgressState.upcoming,
          etaSeconds: 15,
          distanceMeters: 0,
          stopsAway: 1,
        ).etaLabel,
        'Arriving',
      );
    });
  });

  group('Phase 6.3 — Route progress summary', () {
    test('returns null when bus is null', () {
      expect(
        etaService.computeRouteProgressSummary(
          route: makeRoute(),
          busPosition: null,
        ),
        isNull,
      );
    });

    test('returns summary with next stop and stops remaining', () {
      final route = makeRoute();
      final bus = makeBusAt(
        pos: const LatLng(0.0, 0.0),
        speed: 30.0,
        nearestStopId: 's1',
      );

      final summary = etaService.computeRouteProgressSummary(
        route: route,
        busPosition: bus,
      );

      expect(summary, isNotNull);
      expect(summary!.nextStop, isNotNull);
      expect(summary.stopsRemaining, greaterThan(0));
      expect(summary.currentSpeedKmh, 30.0);
    });
  });
}
