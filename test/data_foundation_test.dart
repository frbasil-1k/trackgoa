import 'package:flutter_test/flutter_test.dart';
import 'package:trackgoa/data/repositories/bus_repository.dart';
import 'package:trackgoa/data/repositories/route_repository.dart';
import 'package:trackgoa/data/sources/mock_route_data_source.dart';
import 'package:trackgoa/data/sources/simulated_bus_data_source.dart';
import 'package:trackgoa/features/tracking/services/bus_simulation_engine.dart';

void main() {
  test('Goa route fixtures expose ordered routes and stops', () async {
    final repository = RouteRepository(const MockRouteDataSource());

    final routes = await repository.getRoutes();

    expect(routes.map((route) => route.shortName), ['R1', 'R2', 'R3']);
    expect(routes.every((route) => route.stops.length >= 4), isTrue);
    expect(
      routes.every(
        (route) => route.stops.asMap().entries.every(
          (entry) => entry.key == entry.value.order,
        ),
      ),
      isTrue,
    );
    expect((await repository.getRouteById('r1'))?.destination, 'Miramar');
  });

  group('Bus simulation engine (Phase 6.1)', () {
    test('engine exposes live bus positions filtered by route id', () async {
      final routeRepo = RouteRepository(const MockRouteDataSource());
      final routes = await routeRepo.getRoutes();
      final r1 = routes.firstWhere((r) => r.id == 'r1');

      final engine = BusSimulationEngine();
      addTearDown(engine.dispose);

      engine.startRoute(r1);

      // Position snapshot is immediately available once a route is started.
      final snapshot = engine.getPositionsForRoute('r1');
      expect(snapshot, isNotEmpty);
      expect(snapshot.every((p) => p.busId.startsWith('r1-')), isTrue);
    });

    test('SimulatedBusDataSource satisfies the BusRepository stream contract',
        () async {
      final routeRepo = RouteRepository(const MockRouteDataSource());
      final routes = await routeRepo.getRoutes();
      final r1 = routes.firstWhere((r) => r.id == 'r1');

      final engine = BusSimulationEngine();
      addTearDown(engine.dispose);
      engine.startRoute(r1);

      final dataSource = SimulatedBusDataSource(engine);
      final repository = BusRepository(dataSource);

      // First emission is the immediate snapshot for the requested route.
      final first = await repository.watchBusPositions('r1').first;
      expect(first, isNotEmpty);
      expect(first.every((p) => p.busId.startsWith('r1-')), isTrue);
    });
  });
}
