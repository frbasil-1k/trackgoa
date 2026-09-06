import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/analytics_model.dart';
import '../models/bus_position.dart';
import '../models/favorites_model.dart';
import '../sources/bus_data_source.dart';
import '../sources/mock_route_data_source.dart';
import '../sources/route_data_source.dart';
import '../sources/simulated_bus_data_source.dart';
import 'analytics_repository.dart';
import 'bus_repository.dart';
import 'favorites_repository.dart';
import 'route_repository.dart';
import '../../features/tracking/services/bus_simulation_engine.dart';

/// Source providers centralize the future mock-to-backend implementation swap.
final routeDataSourceProvider = Provider<RouteDataSource>(
  (ref) => const MockRouteDataSource(),
);
final busDataSourceProvider = Provider<BusDataSource>(
  (ref) => const MockBusDataSource(),
);

/// Phase 6.1 — Auto-disposed singleton simulation engine.
/// Initialized with all routes from [routeDataSourceProvider] on first access.
/// All bus-position consumers share this same engine instance.
final busSimulationEngineProvider = Provider<BusSimulationEngine>((ref) {
  final engine = BusSimulationEngine();

  // Warm up with all known routes so the simulation is ready before
  // any tracking screen subscribes.
  final routeDataSource = ref.watch(routeDataSourceProvider);
  routeDataSource.getRoutes().then((routes) {
    for (final route in routes) {
      engine.startRoute(route);
    }
  });

  ref.onDispose(engine.dispose);
  return engine;
});

/// Phase 6.1 — Stream provider for live bus positions on a specific route.
///
/// Returns an empty list if the route hasn't been pre-warmed yet (which should
/// never happen in practice since [busSimulationEngineProvider] warms all routes
/// at startup).
final simulatedBusPositionsProvider =
    StreamProvider.family<List<BusPosition>, String>((ref, routeId) {
  final engine = ref.watch(busSimulationEngineProvider);

  return engine.positionsStream.map((positions) {
    return positions
        .where((p) => p.busId.startsWith('$routeId-'))
        .toList(growable: false);
  });
});

/// Phase 6.1 — Stream of all live bus positions across every route.
/// Use this for a global live-map overview or analytics dashboard.
final allSimulatedBusPositionsProvider =
    StreamProvider<List<BusPosition>>((ref) {
  final engine = ref.watch(busSimulationEngineProvider);
  return engine.positionsStream;
});

final routeRepositoryProvider = Provider<RouteRepository>(
  (ref) => RouteRepository(ref.watch(routeDataSourceProvider)),
);

/// Phase 6.1 — Repository wired to the simulation engine.
///
/// The [BusRepository] wraps [SimulatedBusDataSource] which forwards to the
/// [BusSimulationEngine]. This means the repository layer transparently uses
/// simulation when no real GPS backend is connected, keeping Phase 10 WebSocket
/// integration as a clean swap-in.
///
/// The engine is already pre-warmed with all routes by
/// [busSimulationEngineProvider], so we just hand it to the data source.
final busRepositoryProvider = Provider<BusRepository>((ref) {
  final engine = ref.watch(busSimulationEngineProvider);
  final dataSource = SimulatedBusDataSource(engine);
  return BusRepository(dataSource);
});

/// Stub bus data source for [busDataSourceProvider] until Phase 10.
/// Provides the same contract as [SimulatedBusDataSource] but returns an empty
/// stream so existing Phase 2–5 code continues to compile.
class MockBusDataSource implements BusDataSource {
  const MockBusDataSource();

  @override
  Stream<List<BusPosition>> watchBusPositions(String routeId) =>
      Stream.value(const <BusPosition>[]);
}

// ─── Phase 6.4 — Analytics ───────────────────────────────────────────────────

/// Data source provider — swap this for a real REST/WebSocket source later.
final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => const MockAnalyticsRepository(),
);

/// All route analytics bundles.
final allAnalyticsProvider = FutureProvider<List<AnalyticsBundle>>((ref) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getAllAnalytics();
});

/// Analytics bundle for a specific route.
final analyticsForRouteProvider =
    FutureProvider.family<AnalyticsBundle?, String>((ref, routeId) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getAnalyticsForRoute(routeId);
});

// ─── Phase 6.5 — Favorites ─────────────────────────────────────────────────────

/// SharedPreferences instance — initialized once at app startup.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences must be overridden in ProviderScope.overrides',
  );
});

/// Favorites repository wired to the persisted SharedPreferences instance.
final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(ref.watch(sharedPreferencesProvider));
});

/// In-memory favorites state — persisted to SharedPreferences on every mutation.
class FavoritesNotifier extends StateNotifier<FavoritesState> {
  FavoritesNotifier(this._repo) : super(_repo.load());

  final FavoritesRepository _repo;

  /// Toggles [routeId] in/out of favorites. Returns the updated state.
  Future<FavoritesState> toggleFavorite(String routeId) async {
    state = await _repo.toggleFavorite(state, routeId);
    return state;
  }

  /// Records that the user opened [routeId] and moves it to the front of recents.
  Future<FavoritesState> touchRecent(String routeId) async {
    state = await _repo.touchRecent(state, routeId);
    return state;
  }

  /// Removes [routeId] from both favorites and recents.
  Future<FavoritesState> removeRoute(String routeId) async {
    state = await _repo.removeAll(routeId);
    return state;
  }
}

/// Global favorites state notifier, shared across all consumers.
final favoritesNotifierProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
  final repo = ref.watch(favoritesRepositoryProvider);
  return FavoritesNotifier(repo);
});

/// Convenience: is [routeId] currently a favorite?
final isFavoriteProvider = Provider.family<bool, String>((ref, routeId) {
  return ref.watch(favoritesNotifierProvider).isFavorite(routeId);
});
