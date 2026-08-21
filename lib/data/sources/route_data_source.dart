import '../models/route_model.dart';

/// Source contract for static route data, independent of mock or API storage.
abstract interface class RouteDataSource {
  Future<List<RouteModel>> getRoutes();
  Future<RouteModel?> getRouteById(String routeId);
}
