import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
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
  static const _cities = ['Panaji', 'Margao', 'Vasco', 'Miramar'];
  String _selectedCity = 'Panaji';
  bool _lowBandwidth = false;

  @override
  Widget build(BuildContext context) {
    final routes = ref.watch(homeRoutesProvider);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [Color(0xFFE8F5F5), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: routes.when(
                data: (items) => _HomeContent(
                  cities: _cities,
                  selectedCity: _selectedCity,
                  lowBandwidth: _lowBandwidth,
                  routes: items,
                  onCitySelected: (city) =>
                      setState(() => _selectedCity = city),
                  onBandwidthChanged: (value) =>
                      setState(() => _lowBandwidth = value),
                ),
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
    required this.lowBandwidth,
    required this.routes,
    required this.onCitySelected,
    required this.onBandwidthChanged,
  });
  final List<String> cities;
  final String selectedCity;
  final bool lowBandwidth;
  final List<RouteModel> routes;
  final ValueChanged<String> onCitySelected;
  final ValueChanged<bool> onBandwidthChanged;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.xxl,
    ),
    children: [
      const _HomeHeader(),
      const SizedBox(height: AppSpacing.lg),
      const PrimarySearchBar(hintText: 'Where are you going?'),
      const SizedBox(height: AppSpacing.xl),
      const SectionHeader(title: 'Explore Goa'),
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
      const SectionHeader(title: 'Featured live routes'),
      const SizedBox(height: AppSpacing.xs),
      ...routes.asMap().entries.map(
        (entry) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: RouteCard(
            route: entry.value,
            reliabilityPercent: 92 - (entry.key * 3),
            onTap: () => context.push(RoutePaths.trackingFor(entry.value.id)),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      const SectionHeader(title: 'Nearby buses'),
      const SizedBox(height: AppSpacing.xs),
      ...routes
          .take(3)
          .toList()
          .asMap()
          .entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _NearbyBusCard(route: entry.value, index: entry.key),
            ),
          ),
      const SizedBox(height: AppSpacing.sm),
      const SectionHeader(title: 'Favorite Routes'),
      const SizedBox(height: AppSpacing.xs),
      _FavoritesPreview(routes: routes),
      const SizedBox(height: AppSpacing.sm),
      _BandwidthToggle(value: lowBandwidth, onChanged: onBandwidthChanged),
    ],
  );
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
        ),
        child: const Icon(Icons.directions_bus_rounded, color: Colors.white),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TrackGoa', style: Theme.of(context).textTheme.headlineSmall),
            Text(
              'Move through Goa with confidence.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      const Icon(
        Icons.location_on_outlined,
        color: AppColors.primary,
        size: 18,
      ),
      const SizedBox(width: AppSpacing.xxs),
      Text('Goa', style: Theme.of(context).textTheme.labelMedium),
    ],
  );
}

class _NearbyBusCard extends StatelessWidget {
  const _NearbyBusCard({required this.route, required this.index});
  final RouteModel route;
  final int index;

  @override
  Widget build(BuildContext context) {
    final delayed = index == 1;
    return AppCard(
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
                Text(
                  '${route.shortName} shuttle',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Next: ${route.stops[1].name}  •  ~${4 + index * 2} min',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          delayed ? StatusPill.delayed() : StatusPill.running(),
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
                            const Icon(Icons.access_time_rounded,
                                size: 11, color: AppColors.textSecondary),
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
                                color: AppColors.textSecondary.withValues(alpha: 0.5),
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
                foregroundColor: AppColors.primary,
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
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bookmark_border_rounded,
                color: AppColors.primary, size: 24),
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
              foregroundColor: AppColors.primary,
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
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: value ? AppColors.primaryContainer : AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      border: Border.all(color: AppColors.outline),
    ),
    child: Row(
      children: [
        const Icon(Icons.network_cell_outlined),
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
