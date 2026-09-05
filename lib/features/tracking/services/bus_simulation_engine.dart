import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/bus_position.dart';
import '../../../data/models/route_model.dart';
import 'polyline_navigation_service.dart';

/// Phase 6.1 — Live bus movement engine.
///
/// Drives one or more simulated buses along each subscribed [RouteModel]'s
/// OSRM polyline. Every [tickInterval] milliseconds each bus advances its
/// position by a constant distance calibrated to the route's expected travel
/// time. When a bus reaches the end of the polyline, it loops back to the
/// start so the simulation never stops.
///
/// Architecture is designed to be drop-in replaceable: when real WebSocket GPS
/// data arrives (Phase 10) the same `Stream<List<BusPosition>>` contract is
/// satisfied by a `WebsocketBusDataSource`, and no UI or provider code needs
/// to change.
///
/// ## Design
/// - Per-route buses are tracked in a private [Map].
/// - A single periodic [Timer] drives all routes; the timer starts on the
///   first route subscription and stops when the last route is unsubscribed.
/// - The original (un-simplified) OSRM polyline is used to preserve road
///   accuracy for live movement.
class BusSimulationEngine {
  /// Creates an idle simulation engine. Call [startRoute] to begin.
  BusSimulationEngine() : _routes = {};

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Starts simulation for [route]. Idempotent.
  ///
  /// Two buses are spawned per route, evenly spaced on the polyline loop so
  /// both are always visible on screen.
  void startRoute(RouteModel route) {
    if (_routes.containsKey(route.id)) return;
    if (route.polylinePoints.length < 2) return;

    final totalLengthMeters =
        _navigation.calculatePolylineLength(route.polylinePoints);
    if (totalLengthMeters <= 0) return;

    final avgSpeedKmh = _calibrateSpeedKmh(
      totalLengthMeters: totalLengthMeters,
      estimatedTravelMinutes: route.estimatedTravelMinutes,
    );

    final initialBuses = [
      _initialBus(
        busId: '${route.id}-bus-1',
        routeId: route.id,
        polyline: route.polylinePoints,
        totalLengthMeters: totalLengthMeters,
        speedKmh: avgSpeedKmh,
        startDistanceMeters: 0,
        color: route.color,
      ),
      _initialBus(
        busId: '${route.id}-bus-2',
        routeId: route.id,
        polyline: route.polylinePoints,
        totalLengthMeters: totalLengthMeters,
        speedKmh: avgSpeedKmh,
        startDistanceMeters: totalLengthMeters / 2,
        color: route.color,
      ),
    ];

    _routes[route.id] = _RouteSimulation(route: route, buses: initialBuses);
    _ensureTimerRunning();
  }

  /// Stops simulation for the given route and removes its buses. Idempotent.
  void stopRoute(String routeId) {
    _routes.remove(routeId);
    _stopTimerIfIdle();
  }

  /// Returns a snapshot of all current [BusPosition]s for [routeId].
  List<BusPosition> getPositionsForRoute(String routeId) {
    final sim = _routes[routeId];
    if (sim == null) return const [];
    return sim.buses
        .map((bus) => _toBusPosition(bus, sim.route))
        .toList(growable: false);
  }

  /// Returns a snapshot of all current [BusPosition]s across all active routes.
  List<BusPosition> getAllPositions() {
    return [
      for (final sim in _routes.values)
        for (final bus in sim.buses) _toBusPosition(bus, sim.route),
    ];
  }

  /// Broadcast stream that emits all current bus positions every [tickInterval].
  ///
  /// The engine is warmed up on first access, so subscribers always receive
  /// data without needing to call [startRoute] themselves.
  Stream<List<BusPosition>> get positionsStream {
    _ensureTimerRunning();
    return _controller.stream;
  }

  /// Returns true if [routeId] has been registered with [startRoute].
  bool isRouteActive(String routeId) => _routes.containsKey(routeId);

  /// Disposes the engine: stops the timer, clears state, and closes the stream.
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _routes.clear();
    _controller.close();
  }

  // ─── Internals ────────────────────────────────────────────────────────────

  /// How often the engine advances all buses.
  static const Duration tickInterval = Duration(milliseconds: 500);

  /// The bus travels at this constant speed (km/h). Calibrated per-route via
  /// [RouteModel.estimatedTravelMinutes] but clamped to a realistic urban
  /// range so short dev routes don't produce absurd speeds.
  static const double _maxSpeedKmh = 40.0;
  static const double _minSpeedKmh = 8.0;

  static final PolylineNavigationService _navigation =
      const PolylineNavigationService();

  final Map<String, _RouteSimulation> _routes;
  final StreamController<List<BusPosition>> _controller =
      StreamController<List<BusPosition>>.broadcast();

  Timer? _timer;

  void _ensureTimerRunning() {
    if (_timer != null && _timer!.isActive) return;
    _timer = Timer.periodic(tickInterval, (_) => _tick());
  }

  void _stopTimerIfIdle() {
    if (_routes.isEmpty) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _tick() {
    if (_routes.isEmpty) return;

    // Distance traveled in one tick at the bus's calibrated speed.
    for (final sim in _routes.values) {
      for (final bus in sim.buses) {
        final deltaMeters = (bus.speedKmh * 1000 / 3600) *
            (tickInterval.inMilliseconds / 1000.0);

        bus.currentDistanceMeters += deltaMeters;

        // Loop back to the start of the polyline when reaching the end.
        if (bus.currentDistanceMeters >= bus.totalLengthMeters) {
          bus.currentDistanceMeters = 0.0;
        }

        // Update the interpolated position + heading.
        final interpolated = _navigation.interpolateAlongPolyline(
          bus.polyline,
          bus.currentDistanceMeters,
        );
        if (interpolated != null) {
          bus.currentLatLng = interpolated.position;
          bus.headingDegrees = interpolated.bearing;
        }
      }
    }

    if (_controller.hasListener) {
      _controller.add(getAllPositions());
    }
  }

  _BusSimulation _initialBus({
    required String busId,
    required String routeId,
    required List<LatLng> polyline,
    required double totalLengthMeters,
    required double speedKmh,
    required double startDistanceMeters,
    required Color color,
  }) {
    final interpolated = _navigation.interpolateAlongPolyline(
      polyline,
      startDistanceMeters,
    );
    return _BusSimulation(
      busId: busId,
      routeId: routeId,
      polyline: polyline,
      totalLengthMeters: totalLengthMeters,
      speedKmh: speedKmh,
      currentDistanceMeters: startDistanceMeters,
      currentLatLng: interpolated?.position ?? polyline.first,
      headingDegrees: interpolated?.bearing ?? 0.0,
      color: color,
    );
  }

  /// Calibrates a realistic moving speed (km/h) for a route.
  ///
  /// Uses the route's [RouteModel.estimatedTravelMinutes] as the dominant
  /// signal, but clamps to a realistic urban-bus range so short test routes
  /// (e.g. 1 km / 4 min) don't produce absurd speeds.
  double _calibrateSpeedKmh({
    required double totalLengthMeters,
    required int estimatedTravelMinutes,
  }) {
    if (estimatedTravelMinutes <= 0 || totalLengthMeters <= 0) {
      return (_minSpeedKmh + _maxSpeedKmh) / 2;
    }
    final derivedKmh = (totalLengthMeters / 1000.0) /
        (estimatedTravelMinutes / 60.0);
    return derivedKmh.clamp(_minSpeedKmh, _maxSpeedKmh);
  }

  BusPosition _toBusPosition(_BusSimulation bus, RouteModel route) {
    String? nearestStopId;
    String? nextStopId;
    double? distToNextStop;

    if (route.stops.isNotEmpty) {
      double minDist = double.infinity;
      for (final stop in route.stops) {
        final d = _navigation.calculateDistance(
          bus.currentLatLng,
          stop.coordinates,
        );
        if (d < minDist) {
          minDist = d;
          nearestStopId = stop.id;
        }
      }

      final nearestIndex = route.stops.indexWhere((s) => s.id == nearestStopId);
      if (nearestIndex != -1) {
        final nextIndex = (nearestIndex + 1) % route.stops.length;
        nextStopId = route.stops[nextIndex].id;
        distToNextStop = _navigation.calculateDistance(
          bus.currentLatLng,
          route.stops[nextIndex].coordinates,
        );
      }
    }

    return BusPosition(
      busId: bus.busId,
      coordinates: bus.currentLatLng,
      headingDegrees: bus.headingDegrees,
      speedKmh: bus.speedKmh,
      timestamp: DateTime.now(),
      nearestStopId: nearestStopId,
      nextStopId: nextStopId,
      distanceRemainingToNextStopMeters: distToNextStop,
    );
  }
}

// ─── Private data structures ────────────────────────────────────────────────

class _RouteSimulation {
  _RouteSimulation({required this.route, required this.buses});

  final RouteModel route;
  final List<_BusSimulation> buses;
}

class _BusSimulation {
  _BusSimulation({
    required this.busId,
    required this.routeId,
    required this.polyline,
    required this.totalLengthMeters,
    required this.speedKmh,
    required this.currentDistanceMeters,
    required this.currentLatLng,
    required this.headingDegrees,
    required this.color,
  });

  final String busId;
  final String routeId;
  final List<LatLng> polyline;
  final double totalLengthMeters;
  final double speedKmh;
  final Color color;

  double currentDistanceMeters;
  LatLng currentLatLng;
  double headingDegrees;
}
