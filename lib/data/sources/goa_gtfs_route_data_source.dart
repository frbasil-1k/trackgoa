import '../gtfs/generated_goa_transit_data.dart';
import '../models/route_model.dart';
import 'route_data_source.dart';

/// Production route data source consuming the official Government of Goa
/// Department of Transport GTFS dataset preprocessed for SMART-GO.
///
/// Official Source: https://goatransport.gov.in/GTFS
/// License: Creative Commons Attribution 4.0 International (CC BY 4.0)
/// Operating Agency: Kadamba Transport Corporation Limited (KTCL)
class GoaGtfsRouteDataSource implements RouteDataSource {
  const GoaGtfsRouteDataSource();

  @override
  Future<List<RouteModel>> getRoutes() async {
    return List.unmodifiable(GeneratedGoaTransitData.routes);
  }

  @override
  Future<RouteModel?> getRouteById(String routeId) async {
    final lowerId = routeId.toLowerCase();
    for (final route in GeneratedGoaTransitData.routes) {
      if (route.id.toLowerCase() == lowerId) {
        return route;
      }
    }
    return null;
  }
}
