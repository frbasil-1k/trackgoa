import '../models/bus_position.dart';
import '../models/route_model.dart';
import '../../features/tracking/services/bus_simulation_engine.dart';
import 'bus_data_source.dart';

/// Phase 6.1 — Stream-shaped bus-position source backed by [BusSimulationEngine].
///
/// Wraps the engine's broadcast stream so it satisfies the [BusDataSource]
/// interface contract. Multiple subscribers to the same route share the same
/// underlying simulation; the engine's global timer starts on first subscription
/// and stops when the last subscriber for every route cancels.
class SimulatedBusDataSource implements BusDataSource {
  SimulatedBusDataSource(this._engine);

  final BusSimulationEngine _engine;

  @override
  Stream<List<BusPosition>> watchBusPositions(String routeId) async* {
    // Pre-warm: ensure the engine knows about this route.
    // Routes must be registered via [warmUp] before calling this, but we guard
    // against missing registrations so providers can call this directly.
    if (!_engine.isRouteActive(routeId)) {
      // Safety net: cannot start simulation without route geometry.
      // Providers are responsible for pre-warming routes.
      yield const [];
      return;
    }

    yield _engine.getPositionsForRoute(routeId);

    await for (final allPositions in _engine.positionsStream) {
      yield allPositions
          .where((p) => p.busId.startsWith('$routeId-'))
          .toList(growable: false);
    }
  }

  /// Pre-warms the engine with [route] so [watchBusPositions] is ready to emit.
  void warmUp(RouteModel route) {
    _engine.startRoute(route);
  }

  /// Stops simulation for [routeId].
  void coolDown(String routeId) {
    _engine.stopRoute(routeId);
  }
}
