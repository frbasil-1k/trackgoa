import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sources/bus_data_source.dart';
import '../sources/mock_route_data_source.dart';
import '../sources/route_data_source.dart';
import '../sources/simulated_bus_data_source.dart';
import 'bus_repository.dart';
import 'route_repository.dart';

/// Source providers centralize the future mock-to-backend implementation swap.
final routeDataSourceProvider = Provider<RouteDataSource>(
  (ref) => const MockRouteDataSource(),
);
final busDataSourceProvider = Provider<BusDataSource>(
  (ref) => const SimulatedBusDataSource(),
);

final routeRepositoryProvider = Provider<RouteRepository>(
  (ref) => RouteRepository(ref.watch(routeDataSourceProvider)),
);
final busRepositoryProvider = Provider<BusRepository>(
  (ref) => BusRepository(ref.watch(busDataSourceProvider)),
);
