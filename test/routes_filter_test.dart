import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackgoa/features/routes/providers/route_list_providers.dart';

void main() {
  group('Route Filter & Providers Test', () {
    test('initial filter state is default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final filterState = container.read(routeFilterProvider);
      expect(filterState.searchQuery, '');
      expect(filterState.selectedCity, 'All');
    });

    test('search query matches route name, shortName, origin, destination and stops', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Wait for the data layer to load routes
      await container.read(routesListProvider.future);

      // Search by short name R1
      container.read(routeFilterProvider.notifier).setSearchQuery('r1');
      var filtered = container.read(filteredRoutesProvider).value!;
      expect(filtered.length, 1);
      expect(filtered.first.id, 'r1');

      // Search by stop name 'Campal'
      container.read(routeFilterProvider.notifier).setSearchQuery('campal');
      filtered = container.read(filteredRoutesProvider).value!;
      expect(filtered.length, 1);
      expect(filtered.first.id, 'r1');

      // Search by destination 'Fatorda'
      container.read(routeFilterProvider.notifier).setSearchQuery('Fatorda');
      filtered = container.read(filteredRoutesProvider).value!;
      expect(filtered.length, 1);
      expect(filtered.first.id, 'r2');
    });

    test('city filter matches any route containing that city in origin, destination, or stops', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Wait for routes to load
      await container.read(routesListProvider.future);

      // Filter by 'Miramar' (which is the destination of R1 and stop in R1)
      container.read(routeFilterProvider.notifier).setSelectedCity('Miramar');
      final filtered = container.read(filteredRoutesProvider).value!;
      expect(filtered.length, 1);
      expect(filtered.first.id, 'r1');

      // Filter by 'Margao'
      container.read(routeFilterProvider.notifier).setSelectedCity('Margao');
      final margaoRoutes = container.read(filteredRoutesProvider).value!;
      expect(margaoRoutes.length, 1);
      expect(margaoRoutes.first.id, 'r2');
    });
  });
}
