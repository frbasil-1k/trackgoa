import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/providers/deployment_providers.dart';
import '../../../core/shared/widgets/app_card.dart';
import '../../../core/shared/widgets/city_chip.dart';
import '../../../core/shared/widgets/favorite_icon_button.dart';
import '../../../core/shared/widgets/primary_search_bar.dart';
import '../../../core/shared/widgets/route_card.dart';
import '../../../core/shared/widgets/section_header.dart';
import '../../../core/shared/widgets/status_pill.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/route_model.dart';
import '../../../data/repositories/repository_providers.dart';
import '../providers/home_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedCity = 'All';
  String _searchQuery = '';
  bool _searchActive = false;
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _lowBandwidth = false;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _activateSearch() {
    setState(() => _searchActive = true);
    _focusNode.requestFocus();
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _searchActive = false;
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(homeRoutesProvider);
    final deploymentCities = ref.watch(deploymentCitiesProvider);
    final cities = ['All', ...deploymentCities];
    final colorScheme = Theme.of(context).colorScheme;

    // Theme-aware gradient: teal tint fades into surface color.
    final gradientTop = Color.lerp(
      colorScheme.surface,
      const Color(0xFFE8F5F5),
      colorScheme.brightness == Brightness.light ? 1.0 : 0.0,
    )!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [gradientTop, colorScheme.surface],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: routesAsync.when(
                data: (allRoutes) {
                  final filteredRoutes = allRoutes.where((route) {
                    // City filter matching: origin, destination, city, or any stop.
                    final matchesCity = _selectedCity == 'All' ||
                        (route.city != null && route.city!.toLowerCase().contains(_selectedCity.toLowerCase())) ||
                        route.origin.toLowerCase().contains(_selectedCity.toLowerCase()) ||
                        route.destination.toLowerCase().contains(_selectedCity.toLowerCase()) ||
                        route.stops.any(
                          (stop) => stop.name.toLowerCase().contains(_selectedCity.toLowerCase()),
                        );
                    if (!matchesCity) return false;

                    // Search query matching: route name, code, origin, destination, stop names.
                    if (_searchQuery.trim().isEmpty) return true;
                    final q = _searchQuery.trim().toLowerCase();
                    return route.name.toLowerCase().contains(q) ||
                        route.shortName.toLowerCase().contains(q) ||
                        route.origin.toLowerCase().contains(q) ||
                        route.destination.toLowerCase().contains(q) ||
                        route.stops.any(
                          (stop) => stop.name.toLowerCase().contains(q),
                        );
                  }).toList();

                  return _HomeContent(
                    cities: cities,
                    selectedCity: _selectedCity,
                    searchQuery: _searchQuery,
                    searchActive: _searchActive,
                    searchController: _searchController,
                    focusNode: _focusNode,
                    lowBandwidth: _lowBandwidth,
                    allRoutes: allRoutes,
                    filteredRoutes: filteredRoutes,
                    onCitySelected: (city) => setState(() => _selectedCity = city),
                    onSearchChanged: (query) => setState(() => _searchQuery = query),
                    onActivateSearch: _activateSearch,
                    onClearSearch: _clearSearch,
                    onBandwidthChanged: (value) => setState(() => _lowBandwidth = value),
                    onResetFilters: () {
                      setState(() {
                        _selectedCity = 'All';
                        _searchController.clear();
                        _searchQuery = '';
                        _searchActive = false;
                      });
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      'Unable to load routes. Please try again.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.cities,
    required this.selectedCity,
    required this.searchQuery,
    required this.searchActive,
    required this.searchController,
    required this.focusNode,
    required this.lowBandwidth,
    required this.allRoutes,
    required this.filteredRoutes,
    required this.onCitySelected,
    required this.onSearchChanged,
    required this.onActivateSearch,
    required this.onClearSearch,
    required this.onBandwidthChanged,
    required this.onResetFilters,
  });

  final List<String> cities;
  final String selectedCity;
  final String searchQuery;
  final bool searchActive;
  final TextEditingController searchController;
  final FocusNode focusNode;
  final bool lowBandwidth;
  final List<RouteModel> allRoutes;
  final List<RouteModel> filteredRoutes;
  final ValueChanged<String> onCitySelected;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onActivateSearch;
  final VoidCallback onClearSearch;
  final ValueChanged<bool> onBandwidthChanged;
  final VoidCallback onResetFilters;

  String? _findMatchingStop(RouteModel route) {
    if (searchQuery.trim().isEmpty) return null;
    final q = searchQuery.trim().toLowerCase();
    for (final stop in route.stops) {
      if (stop.name.toLowerCase().contains(q)) {
        return stop.name;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final nearbyRoutes = filteredRoutes.isNotEmpty ? filteredRoutes : allRoutes;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        const _HomeHeader(),
        const SizedBox(height: AppSpacing.lg),

        // ── Interactive Search ──────────────────────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: searchActive
              ? TextField(
                  key: const ValueKey('home-search-active'),
                  controller: searchController,
                  focusNode: focusNode,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search routes, destinations, stops...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: onClearSearch,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  onChanged: onSearchChanged,
                )
              : PrimarySearchBar(
                  key: const ValueKey('home-search-inactive'),
                  hintText: 'Where are you going in Goa?',
                  onTap: onActivateSearch,
                ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── City Filter Chips ───────────────────────────────────────────────
        SectionHeader(
          title: 'Explore',
          actionLabel: (selectedCity != 'All' || searchQuery.isNotEmpty) ? 'Reset' : null,
          onAction: (selectedCity != 'All' || searchQuery.isNotEmpty) ? onResetFilters : null,
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cities.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.xs),
            itemBuilder: (context, index) {
              final city = cities[index];
              return CityChip(
                label: city,
                isSelected: selectedCity == city,
                onTap: () => onCitySelected(city),
              );
            },
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // ── Filtered / Featured Live Routes ─────────────────────────────────
        SectionHeader(
          title: searchQuery.isNotEmpty
              ? 'Search results (${filteredRoutes.length})'
              : selectedCity == 'All'
                  ? 'Featured live routes'
                  : 'Routes in $selectedCity (${filteredRoutes.length})',
        ),
        const SizedBox(height: AppSpacing.xs),

        if (filteredRoutes.isEmpty)
          _EmptyFilteredRoutes(
            query: searchQuery,
            city: selectedCity,
            onReset: onResetFilters,
          )
        else
          ...filteredRoutes.asMap().entries.map((entry) {
            final route = entry.value;
            final matchingStop = _findMatchingStop(route);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: RouteCard(
                route: route,
                reliabilityPercent: 92 - (entry.key * 3),
                matchingStopName: matchingStop,
                onTap: () => context.push(RoutePaths.trackingFor(route.id)),
              ),
            );
          }),

        const SizedBox(height: AppSpacing.md),

        // ── Nearby buses (Live Simulation) ──────────────────────────────────
        const SectionHeader(title: 'Nearby live buses'),
        const SizedBox(height: AppSpacing.xs),
        ...nearbyRoutes
            .take(3)
            .toList()
            .map(
              (route) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _NearbyBusCard(route: route),
              ),
            ),

        const SizedBox(height: AppSpacing.sm),

        // ── Favorite Routes ─────────────────────────────────────────────────
        const SectionHeader(title: 'Favorite Routes'),
        const SizedBox(height: AppSpacing.xs),
        _FavoritesPreview(routes: allRoutes),

        const SizedBox(height: AppSpacing.sm),

        // ── Bandwidth Mode ──────────────────────────────────────────────────
        _BandwidthToggle(value: lowBandwidth, onChanged: onBandwidthChanged),
      ],
    );
  }
}

class _EmptyFilteredRoutes extends StatelessWidget {
  const _EmptyFilteredRoutes({
    required this.query,
    required this.city,
    required this.onReset,
  });

  final String query;
  final String city;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final message = query.isNotEmpty
        ? 'No routes or stops found matching "$query".'
        : 'No routes operating in $city right now.';

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 44, color: AppColors.inactive),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'No matches found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.tonalIcon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Show all routes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deployment = ref.watch(deploymentProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          ),
          child: Icon(Icons.directions_bus_rounded, color: colorScheme.onPrimary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(deployment.displayName, style: Theme.of(context).textTheme.headlineSmall),
              Text(
                deployment.tagline,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_outlined,
                color: colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                deployment.region,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NearbyBusCard extends ConsumerWidget {
  const _NearbyBusCard({required this.route});
  final RouteModel route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final nextStopName = route.stops.length > 1 ? route.stops[1].name : route.stops.first.name;
    const etaLabel = '~4 min';

    return AppCard(
      onTap: () => context.push(RoutePaths.trackingFor(route.id)),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: route.color.withValues(alpha: 0.14),
            foregroundColor: route.color,
            child: const Icon(Icons.directions_bus_rounded),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${route.shortName} Shuttle',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'to ${route.destination}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Next: $nextStopName  •  $etaLabel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${route.estimatedTravelMinutes} min trip to ${route.destination}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          StatusPill.running(),
        ],
      ),
    );
  }
}

class _FavoritesPreview extends ConsumerWidget {
  const _FavoritesPreview({required this.routes});
  final List<RouteModel> routes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesNotifierProvider);

    if (favorites.favoriteRouteIds.isEmpty) {
      return _EmptyFavoritesHint();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...favorites.favoriteRouteIds.map((id) {
          final route = routes.firstWhere(
            (r) => r.id == id,
            orElse: () => routes.first,
          );
          final reliability = 92 - (route.id.hashCode.abs() % 10);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              onTap: () async {
                await ref
                    .read(favoritesNotifierProvider.notifier)
                    .touchRecent(route.id);
                if (context.mounted) {
                  context.push(RoutePaths.trackingFor(route.id));
                }
              },
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: route.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      route.shortName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: route.color,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${route.origin} → ${route.destination}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 11,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '~${route.estimatedTravelMinutes} min',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$reliability% reliable',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  FavoriteIconButton(routeId: route.id, size: 32, iconSize: 16),
                ],
              ),
            ),
          );
        }),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.push(RoutePaths.favorites),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('View all'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyFavoritesHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.bookmark_border_rounded,
                color: colorScheme.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Save your favorite routes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap the bookmark icon on any route to add it here.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push(RoutePaths.favorites),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

class _BandwidthToggle extends StatelessWidget {
  const _BandwidthToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: value ? colorScheme.primaryContainer : colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        children: [
          Icon(Icons.network_cell_outlined, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Low bandwidth mode',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Use a lighter experience when needed.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
