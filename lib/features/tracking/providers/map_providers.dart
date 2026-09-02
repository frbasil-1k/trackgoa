import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/utils/polyline_simplifier.dart';
import '../../../data/models/route_model.dart';
import '../../../data/repositories/repository_providers.dart';

/// MapController lifecycle managed by Riverpod.
final mapControllerProvider = Provider.autoDispose<MapController>((ref) {
  final controller = MapController();
  ref.onDispose(controller.dispose);
  return controller;
});

/// Fetches the selected route by ID for the tracking screen.
final selectedRouteProvider =
    FutureProvider.autoDispose.family<RouteModel?, String>((ref, routeId) async {
  final repository = ref.watch(routeRepositoryProvider);
  return repository.getRouteById(routeId);
});

/// Provides simplified polyline for rendering (computed once and cached).
///
/// Uses Douglas-Peucker algorithm with 8m tolerance to reduce point count
/// while preserving road shape. Original polyline kept for Phase 6 navigation.
final simplifiedPolylineProvider =
    Provider.autoDispose.family<List<LatLng>, String>((ref, routeId) {
  final routeAsync = ref.watch(selectedRouteProvider(routeId));

  return routeAsync.when(
    data: (route) {
      if (route == null) return [];
      return PolylineSimplifier.simplify(route.polylinePoints, epsilon: 8.0);
    },
    loading: () => [],
    error: (e, _) => [],
  );
});
