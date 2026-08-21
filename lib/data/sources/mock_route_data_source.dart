import '../mock/mock_routes.dart';
import '../models/route_model.dart';
import 'route_data_source.dart';

/// In-memory implementation used until a routes backend is introduced.
class MockRouteDataSource implements RouteDataSource {
  const MockRouteDataSource();

  @override
  Future<List<RouteModel>> getRoutes() async => List.unmodifiable(mockRoutes);

  @override
  Future<RouteModel?> getRouteById(String routeId) async {
    for (final route in mockRoutes) {
      if (route.id == routeId) return route;
    }
    return null;
  }
}
