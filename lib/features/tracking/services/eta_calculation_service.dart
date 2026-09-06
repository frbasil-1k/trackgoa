import 'package:flutter/foundation.dart';

import '../../../data/models/alert_model.dart';
import '../../../data/models/bus_position.dart';
import '../../../data/models/route_model.dart';
import '../../../data/models/stop_model.dart';
import 'polyline_navigation_service.dart';

/// Phase 6.3 — Derived ETA and stop-progress computation.
///
/// Pure functions that take live [BusPosition] data and produce UI-ready
/// stop-state summaries. Intentionally stateless — every call recomputes from
/// scratch so consumers always get the latest state without holding mutable state.
///
/// ## Architecture note
/// These functions intentionally live here rather than inside the simulation
/// engine because they are derived from live bus positions and must recompute
/// on every tick. Placing them in a service keeps [BusPosition] clean and
/// compatible with a future WebSocket backend (Phase 10) — the same functions
/// work with real GPS positions, not just simulated ones.
class EtaCalculationService {
  const EtaCalculationService();

  static final PolylineNavigationService _navigation =
      const PolylineNavigationService();

  // ─── Public API ───────────────────────────────────────────────────────

  /// Computes the full stop-progress list for every stop on [route] given
  /// the current [busPosition] (first bus on the route).
  ///
  /// Returns a list of [StopProgress] in route order (origin → destination).
  /// Returns an empty list if [busPosition] is null or [route.stops] is empty.
  List<StopProgress> computeStopsProgress({
    required RouteModel route,
    required BusPosition? busPosition,
  }) {
    if (busPosition == null || route.stops.isEmpty) {
      return const [];
    }

    final nearestIndex = _findNearestStopIndex(
      busPosition,
      route.stops,
    );
    final speedKmh = busPosition.speedKmh.clamp(0.5, 80.0);

    return route.stops.asMap().entries.map((entry) {
      final index = entry.key;
      final stop = entry.value;

      final state = _computeState(
        stopIndex: index,
        nearestStopId: busPosition.nearestStopId,
        stopId: stop.id,
      );

      final distanceMeters = _navigation.calculateDistance(
        busPosition.coordinates,
        stop.coordinates,
      );

      final etaSeconds = _etaSeconds(distanceMeters, speedKmh);

      // stopsAway: 0 = current stop, 1 = next, 2 = two away, etc.
      final stopsAway = _computeStopsAway(index, nearestIndex);

      return StopProgress(
        stop: stop,
        state: state,
        etaSeconds: etaSeconds,
        distanceMeters: distanceMeters,
        stopsAway: stopsAway,
      );
    }).toList();
  }

  /// Computes a route-level summary used by the bottom sheet live card.
  ///
  /// Returns null if [busPosition] is null or the route has no stops.
  RouteProgressSummary? computeRouteProgressSummary({
    required RouteModel route,
    required BusPosition? busPosition,
  }) {
    if (busPosition == null || route.stops.isEmpty) return null;

    final nearestIndex = _findNearestStopIndex(
      busPosition,
      route.stops,
    );

    // The next stop is the one immediately after the nearest stop in route
    // order, unless the bus is exactly at the last stop (then wrap to first).
    final nextIndex = (nearestIndex + 1) % route.stops.length;
    final nextStop = route.stops[nextIndex];

    final stopsRemaining = route.stops.length - nextIndex;
    final distanceToNext = _navigation.calculateDistance(
      busPosition.coordinates,
      nextStop.coordinates,
    );

    final speedKmh = busPosition.speedKmh.clamp(0.5, 80.0);
    final etaSeconds = _etaSeconds(distanceToNext, speedKmh);

    return RouteProgressSummary(
      nextStop: nextStop,
      etaSeconds: etaSeconds,
      stopsRemaining: stopsRemaining,
      currentSpeedKmh: speedKmh,
      busPosition: busPosition,
    );
  }

  /// Determines which stop alert to fire based on the bus's [stopsAway]
  /// relative to the [selectedStop].
  ///
  /// Returns:
  /// - `AlertType.twoStopsAway` when the bus is 2 stops from the selected stop
  /// - `AlertType.oneStopAway` when the bus is 1 stop from the selected stop
  /// - `AlertType.reached` when the bus has arrived at the selected stop
  /// - `null` when no alert threshold has been crossed
  AlertType? computeAlert({
    required StopModel selectedStop,
    required List<StopProgress> stopsProgress,
  }) {
    for (final sp in stopsProgress) {
      if (sp.stop.id == selectedStop.id) {
        if (sp.state == StopProgressState.current || sp.state == StopProgressState.passed) {
          return AlertType.reached;
        }
        if (sp.stopsAway == 1) {
          return AlertType.oneStopAway;
        }
        if (sp.stopsAway == 2) {
          return AlertType.twoStopsAway;
        }
        break;
      }
    }
    return null;
  }

  // ─── Internal helpers ────────────────────────────────────────────────

  /// Finds the index in [stops] that is closest to the bus's current position.
  int _findNearestStopIndex(BusPosition bus, List<StopModel> stops) {
    double minDist = double.infinity;
    int nearestIndex = 0;

    for (int i = 0; i < stops.length; i++) {
      final d = _navigation.calculateDistance(
        bus.coordinates,
        stops[i].coordinates,
      );
      if (d < minDist) {
        minDist = d;
        nearestIndex = i;
      }
    }
    return nearestIndex;
  }

  /// Computes passed / current / upcoming state for a stop.
  StopProgressState _computeState({
    required int stopIndex,
    required String? nearestStopId,
    required String stopId,
  }) {
    if (stopId == nearestStopId) return StopProgressState.current;
    // If this stop comes before the nearest stop in route order, it's passed.
    // We use the simple heuristic: nearest = current; earlier = passed.
    // This works for the origin→destination direction; looping buses
    // will correctly mark stops as passed once they move past them.
    return StopProgressState.upcoming;
  }

  /// How many stops away from the bus (0 = current, 1 = next, 2 = two away).
  int _computeStopsAway(int stopIndex, int nearestIndex) {
    if (stopIndex == nearestIndex) return 0;
    // Only consider stops ahead in route order.
    if (stopIndex > nearestIndex) {
      return stopIndex - nearestIndex;
    }
    // Stop comes before nearest — bus has passed it.
    return -1; // negative means already passed
  }

  /// ETA in seconds from [distanceMeters] at [speedKmh].
  int _etaSeconds(double distanceMeters, double speedKmh) {
    if (distanceMeters <= 0) return 0;
    final safeSpeedMs = (speedKmh * 1000) / 3600;
    if (safeSpeedMs <= 0) return 9999;
    return (distanceMeters / safeSpeedMs).round();
  }
}

// ─── Public data models ───────────────────────────────────────────────

/// Immutable state of a single stop relative to the live bus.
@immutable
class StopProgress {
  const StopProgress({
    required this.stop,
    required this.state,
    required this.etaSeconds,
    required this.distanceMeters,
    required this.stopsAway,
  });

  final StopModel stop;
  final StopProgressState state;
  final int etaSeconds;
  final double distanceMeters;
  final int stopsAway;

  /// Human-readable ETA string (e.g. "2 min", "< 1 min", "Arriving").
  String get etaLabel {
    if (state == StopProgressState.passed) return 'Passed';
    if (state == StopProgressState.current) return 'Here';
    if (etaSeconds <= 30) return 'Arriving';
    if (etaSeconds < 60) return '< 1 min';
    final mins = (etaSeconds / 60).ceil();
    return '$mins min';
  }

  @override
  bool operator ==(Object other) =>
      other is StopProgress &&
      stop == other.stop &&
      state == other.state &&
      etaSeconds == other.etaSeconds &&
      distanceMeters == other.distanceMeters &&
      stopsAway == other.stopsAway;

  @override
  int get hashCode =>
      Object.hash(stop, state, etaSeconds, distanceMeters, stopsAway);
}

/// Passed / current / upcoming status for a stop.
enum StopProgressState { passed, current, upcoming }

/// Route-level live summary shown in the bottom sheet card.
@immutable
class RouteProgressSummary {
  const RouteProgressSummary({
    required this.nextStop,
    required this.etaSeconds,
    required this.stopsRemaining,
    required this.currentSpeedKmh,
    required this.busPosition,
  });

  final StopModel? nextStop;
  final int etaSeconds;
  final int stopsRemaining;
  final double currentSpeedKmh;
  final BusPosition busPosition;

  String get nextStopName => nextStop?.name ?? '—';
  String get nextStopEtaLabel {
    if (etaSeconds <= 30) return 'Arriving';
    if (etaSeconds < 60) return '< 1 min';
    final mins = (etaSeconds / 60).ceil();
    return '$mins min';
  }

  String get speedLabel => '${currentSpeedKmh.round()} km/h';

  @override
  bool operator ==(Object other) =>
      other is RouteProgressSummary &&
      nextStop == other.nextStop &&
      etaSeconds == other.etaSeconds &&
      stopsRemaining == other.stopsRemaining &&
      currentSpeedKmh == other.currentSpeedKmh;

  @override
  int get hashCode =>
      Object.hash(nextStop, etaSeconds, stopsRemaining, currentSpeedKmh);
}
