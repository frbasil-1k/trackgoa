import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/shared/widgets/app_card.dart';
import '../../../core/shared/widgets/route_card.dart';
import '../../../core/shared/widgets/section_header.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/route_model.dart';
import '../providers/route_list_providers.dart';
import '../widgets/route_list_header.dart';

class RouteListScreen extends ConsumerWidget {
  const RouteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredRoutesAsync = ref.watch(filteredRoutesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Routes')),
      body: SafeArea(
        top: false,
        child: filteredRoutesAsync.when(
          data: (routes) => _RouteListContent(routes: routes),
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
    );
  }
}

class _RouteListContent extends StatelessWidget {
  const _RouteListContent({required this.routes});

  final List<RouteModel> routes;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        const RouteListHeader(),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'All routes'),
        const SizedBox(height: AppSpacing.sm),
        if (routes.isEmpty)
          _EmptyState()
        else
          ..._buildAnimatedRouteCards(context, routes),
      ],
    );
  }

  List<Widget> _buildAnimatedRouteCards(
    BuildContext context,
    List<RouteModel> routes,
  ) {
    return routes.asMap().entries.map((entry) {
      final index = entry.key;
      final route = entry.value;

      return TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 180 + (40 * index)),
        curve: Curves.easeOut,
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Hero(
            tag: 'route-${route.id}',
            child: Material(
              type: MaterialType.transparency,
              child: RouteCard(
                route: route,
                reliabilityPercent: 92 - (index * 3),
                onTap: () => context.push(RoutePaths.trackingFor(route.id)),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: 1.0,
        child: AppCard(
          child: Column(
            children: [
              const Icon(Icons.search_off_rounded, size: 48),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No routes found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Try adjusting your search or city filter.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}
