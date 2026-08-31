import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
