import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/route_model.dart';
import '../../../data/repositories/repository_providers.dart';
import '../models/route_filter_state.dart';

/// Notifier managing search query and selected city filter state.
class RouteFilterNotifier extends Notifier<RouteFilterState> {
  @override
  RouteFilterState build() => const RouteFilterState();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSelectedCity(String city) {
    state = state.copyWith(selectedCity: city);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }

  void reset() {
    state = const RouteFilterState();
  }
}

/// State provider for route filtering using Riverpod 3 NotifierProvider pattern.
final routeFilterProvider =
    NotifierProvider<RouteFilterNotifier, RouteFilterState>(
  RouteFilterNotifier.new,
);

/// Raw routes retrieved from the RouteRepository.
final routesListProvider = FutureProvider<List<RouteModel>>(
  (ref) => ref.watch(routeRepositoryProvider).getRoutes(),
);

/// Computed filtered routes taking into account search query and city selection.
final filteredRoutesProvider = Provider<AsyncValue<List<RouteModel>>>((ref) {
  final routesAsync = ref.watch(routesListProvider);
  final filter = ref.watch(routeFilterProvider);

  return routesAsync.whenData((routes) {
    final query = filter.searchQuery.trim().toLowerCase();
    final city = filter.selectedCity;

    return routes.where((route) {
      // City filtering: include any route containing that city (origin, destination, or stop)
      final matchesCity = city == 'All' ||
          route.origin.toLowerCase().contains(city.toLowerCase()) ||
          route.destination.toLowerCase().contains(city.toLowerCase()) ||
          route.stops.any(
            (stop) => stop.name.toLowerCase().contains(city.toLowerCase()),
          );

      if (!matchesCity) return false;

      // Search matching: route name, shortName (R1, R2, etc.), origin, destination, and stop names
      if (query.isEmpty) return true;

      final matchesQuery = route.name.toLowerCase().contains(query) ||
          route.shortName.toLowerCase().contains(query) ||
          route.origin.toLowerCase().contains(query) ||
          route.destination.toLowerCase().contains(query) ||
          route.stops.any(
            (stop) => stop.name.toLowerCase().contains(query),
          );

      return matchesQuery;
    }).toList();
  });
});
