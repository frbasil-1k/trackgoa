import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_go/features/routes/providers/route_list_providers.dart';

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
      container.read(routeFilterProvider.notifier).setSearchQuery('R1');
      var filtered = container.read(filteredRoutesProvider).value!;
      expect(filtered.length, 1);
      expect(filtered.first.id, 'R1');

      // Search by stop name 'Kala Academy'
      container.read(routeFilterProvider.notifier).setSearchQuery('Kala Academy');
      filtered = container.read(filteredRoutesProvider).value!;
      expect(filtered.length, greaterThanOrEqualTo(1));
      expect(filtered.any((r) => r.id == 'R1'), isTrue);

      // Search by destination 'Mapusa'
      container.read(routeFilterProvider.notifier).setSearchQuery('Mapusa');
      filtered = container.read(filteredRoutesProvider).value!;
      expect(filtered.length, 1);
      expect(filtered.first.id, 'PNJ7');
    });

    test('city filter matches any route containing that city in origin, destination, or stops', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Wait for routes to load
      await container.read(routesListProvider.future);

      // Filter by 'Mapusa'
      container.read(routeFilterProvider.notifier).setSelectedCity('Mapusa');
      final mapusaRoutes = container.read(filteredRoutesProvider).value!;
      expect(mapusaRoutes.length, 1);
      expect(mapusaRoutes.first.id, 'PNJ7');

      // Filter by 'Margao'
      container.read(routeFilterProvider.notifier).setSelectedCity('Margao');
      final margaoRoutes = container.read(filteredRoutesProvider).value!;
      expect(margaoRoutes.length, greaterThanOrEqualTo(1));
      expect(margaoRoutes.any((r) => r.id == 'MRG1'), isTrue);

      // Filter by 'Vasco'
      container.read(routeFilterProvider.notifier).setSelectedCity('Vasco');
      final vascoRoutes = container.read(filteredRoutesProvider).value!;
      expect(vascoRoutes.length, greaterThanOrEqualTo(1));
      expect(vascoRoutes.any((r) => r.id == 'MRG11'), isTrue);
    });
  });
}
