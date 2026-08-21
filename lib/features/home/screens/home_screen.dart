import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/shared/widgets/app_card.dart';
import '../../../core/shared/widgets/city_chip.dart';
import '../../../core/shared/widgets/primary_search_bar.dart';
import '../../../core/shared/widgets/route_card.dart';
import '../../../core/shared/widgets/section_header.dart';
import '../../../core/shared/widgets/status_pill.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/route_model.dart';
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
      const SectionHeader(title: 'Favorites'),
      const SizedBox(height: AppSpacing.xs),
      const _FavoritesPreview(),
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

class _FavoritesPreview extends StatelessWidget {
  const _FavoritesPreview();
  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: [
        const Icon(Icons.bookmark_border_rounded, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your shortcuts, ready when you are.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Save routes for quick access.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
      ],
    ),
  );
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
