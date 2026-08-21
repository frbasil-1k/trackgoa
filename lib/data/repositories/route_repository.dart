import '../models/route_model.dart';
import '../sources/route_data_source.dart';

/// Route access boundary for features and Riverpod providers.
class RouteRepository {
  const RouteRepository(this._dataSource);

  final RouteDataSource _dataSource;

  Future<List<RouteModel>> getRoutes() => _dataSource.getRoutes();
  Future<RouteModel?> getRouteById(String routeId) =>
      _dataSource.getRouteById(routeId);
}
