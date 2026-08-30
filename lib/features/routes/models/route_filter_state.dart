import 'package:flutter/foundation.dart';

/// Immutable state for route filtering, search, and city selection.
@immutable
class RouteFilterState {
  const RouteFilterState({
    this.searchQuery = '',
    this.selectedCity = 'All',
  });

  final String searchQuery;
  final String selectedCity;

  RouteFilterState copyWith({
    String? searchQuery,
    String? selectedCity,
  }) =>
      RouteFilterState(
        searchQuery: searchQuery ?? this.searchQuery,
        selectedCity: selectedCity ?? this.selectedCity,
      );

  @override
  bool operator ==(Object other) =>
      other is RouteFilterState &&
      searchQuery == other.searchQuery &&
      selectedCity == other.selectedCity;

  @override
  int get hashCode => Object.hash(searchQuery, selectedCity);
}
