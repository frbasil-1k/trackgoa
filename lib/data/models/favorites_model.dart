import 'package:flutter/foundation.dart';

/// Persisted favorites & recents state.
///
/// Architecture note: this stores only IDs and timestamps, making it trivially
/// syncable with a backend (just send the list of IDs). The full route objects
/// are always fetched from [RouteRepository] when needed.
@immutable
class FavoritesState {
  const FavoritesState({
    required this.favoriteRouteIds,
    required this.recentRouteIds,
  });

  /// Route IDs marked as favorite by the user, in the order they were added.
  final List<String> favoriteRouteIds;

  /// Route IDs the user has opened recently, newest first, capped at 5.
  final List<String> recentRouteIds;

  FavoritesState copyWith({
    List<String>? favoriteRouteIds,
    List<String>? recentRouteIds,
  }) =>
      FavoritesState(
        favoriteRouteIds: favoriteRouteIds ?? this.favoriteRouteIds,
        recentRouteIds: recentRouteIds ?? this.recentRouteIds,
      );

  bool isFavorite(String routeId) => favoriteRouteIds.contains(routeId);
  bool isRecent(String routeId) => recentRouteIds.contains(routeId);

  @override
  bool operator ==(Object other) =>
      other is FavoritesState &&
      listEquals(other.favoriteRouteIds, favoriteRouteIds) &&
      listEquals(other.recentRouteIds, recentRouteIds);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(favoriteRouteIds), Object.hashAll(recentRouteIds));
}
