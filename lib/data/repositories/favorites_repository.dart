import 'package:shared_preferences/shared_preferences.dart';

import '../models/favorites_model.dart';

/// Phase 6.5 — Favorites repository backed by SharedPreferences.
///
/// Provides synchronous reads and async writes so the UI never blocks.
/// Architecture is designed to be a drop-in replacement for a backend sync
/// layer in future phases.
class FavoritesRepository {
  FavoritesRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _kFavorites = 'favorites_route_ids';
  static const _kRecent = 'recent_route_ids';
  static const _maxRecents = 5;

  /// Returns the current persisted state synchronously (avoids async gaps).
  FavoritesState load() {
    final favs = _prefs.getStringList(_kFavorites) ?? const [];
    final recents = _prefs.getStringList(_kRecent) ?? const [];
    return FavoritesState(
      favoriteRouteIds: favs,
      recentRouteIds: recents.take(_maxRecents).toList(),
    );
  }

  /// Persists and returns the new state after adding/removing a favorite.
  Future<FavoritesState> toggleFavorite(FavoritesState current, String routeId) async {
    final newFavs = List<String>.from(current.favoriteRouteIds);
    if (newFavs.contains(routeId)) {
      newFavs.remove(routeId);
    } else {
      newFavs.add(routeId);
    }
    await _prefs.setStringList(_kFavorites, newFavs);
    return current.copyWith(favoriteRouteIds: newFavs);
  }

  /// Adds [routeId] to the front of the recents list (max 5), removing it
  /// from its current position if it was already present.
  Future<FavoritesState> touchRecent(FavoritesState current, String routeId) async {
    final newRecents = List<String>.from(current.recentRouteIds);
    newRecents.remove(routeId); // remove if already present
    newRecents.insert(0, routeId); // bring to front
    if (newRecents.length > _maxRecents) {
      newRecents.removeLast();
    }
    await _prefs.setStringList(_kRecent, newRecents);
    return current.copyWith(recentRouteIds: newRecents);
  }

  /// Removes a route from both favorites and recents.
  Future<FavoritesState> removeAll(String routeId) async {
    final newFavs = List<String>.from(load().favoriteRouteIds)..remove(routeId);
    final newRecents = List<String>.from(load().recentRouteIds)..remove(routeId);
    await Future.wait([
      _prefs.setStringList(_kFavorites, newFavs),
      _prefs.setStringList(_kRecent, newRecents),
    ]);
    return FavoritesState(
      favoriteRouteIds: newFavs,
      recentRouteIds: newRecents,
    );
  }
}
