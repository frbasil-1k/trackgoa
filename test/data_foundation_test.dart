import 'package:flutter_test/flutter_test.dart';
import 'package:trackgoa/data/repositories/bus_repository.dart';
import 'package:trackgoa/data/repositories/route_repository.dart';
import 'package:trackgoa/data/sources/mock_route_data_source.dart';
import 'package:trackgoa/data/sources/simulated_bus_data_source.dart';

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

  test('simulated source already fulfils the future stream contract', () async {
    final repository = BusRepository(const SimulatedBusDataSource());

    await expectLater(repository.watchBusPositions('r1'), emits(<Object>[]));
  });
}
