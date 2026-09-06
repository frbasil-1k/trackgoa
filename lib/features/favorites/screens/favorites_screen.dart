import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/shared/widgets/app_card.dart';
import '../../../core/shared/widgets/favorite_icon_button.dart';
import '../../../core/shared/widgets/status_pill.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/route_model.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../home/providers/home_providers.dart';

/// Phase 6.5 — Saved Routes screen.
///
/// Displays favorite routes (with quick "Track Again" buttons) and a recent
/// routes section. Both pull from [favoritesNotifierProvider] which is backed
/// by [FavoritesRepository] (SharedPreferences).
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesNotifierProvider);
    final allRoutesAsync = ref.watch(homeRoutesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _FavoritesSliverAppBar(),
          allRoutesAsync.when(
            data: (allRoutes) {
              if (favorites.favoriteRouteIds.isEmpty &&
                  favorites.recentRouteIds.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(),
                );
              }
              return SliverList(
                delegate: SliverChildListDelegate([
                  if (favorites.favoriteRouteIds.isNotEmpty) ...[
                    _SectionTitle(
                      title: 'Favorite Routes',
                      count: favorites.favoriteRouteIds.length,
                    ),
                    ...favorites.favoriteRouteIds.map((id) {
                      final route = _findRoute(allRoutes, id);
                      if (route == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        child: _FavoriteRouteCard(route: route),
                      );
                    }),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (favorites.recentRouteIds.isNotEmpty) ...[
                    _SectionTitle(
                      title: 'Recent Routes',
                      count: favorites.recentRouteIds.length,
                    ),
                    ...favorites.recentRouteIds.map((id) {
                      final route = _findRoute(allRoutes, id);
                      if (route == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        child: _RecentRouteCard(route: route),
                      );
                    }),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                ]),
              );
            },
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('Unable to load routes', style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }

  RouteModel? _findRoute(List<RouteModel> routes, String id) {
    try {
      return routes.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ─── Sliver App Bar ──────────────────────────────────────────────────────────

class _FavoritesSliverAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 3)),
              ],
            ),
            child: const Icon(Icons.arrow_back_rounded,
                size: 20, color: AppColors.textPrimary),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: AppSpacing.md, bottom: 16),
        title: Text(
          'Saved Routes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontSize: 22,
              ),
        ),
      ),
    );
  }
}

// ─── Section Title ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Favorite Route Card ─────────────────────────────────────────────────────

class _FavoriteRouteCard extends ConsumerWidget {
  const _FavoriteRouteCard({required this.route});
  final RouteModel route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reliability = 92 - (route.id.hashCode.abs() % 10);
    return AppCard(
      onTap: () => _onTrackAgain(context, ref),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: route.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                ),
                child: Text(
                  route.shortName,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: route.color, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${route.origin} → ${route.destination}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          '~${route.estimatedTravelMinutes} min',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              FavoriteIconButton(routeId: route.id, size: 36, iconSize: 18),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              StatusPill(
                label: '$reliability% reliable',
                color: reliability >= 90
                    ? AppColors.success
                    : (reliability >= 80 ? AppColors.warning : AppColors.danger),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _onTrackAgain(context, ref),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Track Again'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onTrackAgain(BuildContext context, WidgetRef ref) async {
    await ref.read(favoritesNotifierProvider.notifier).touchRecent(route.id);
    if (context.mounted) {
      context.push(RoutePaths.trackingFor(route.id));
    }
  }
}

// ─── Recent Route Card ───────────────────────────────────────────────────────

class _RecentRouteCard extends ConsumerWidget {
  const _RecentRouteCard({required this.route});
  final RouteModel route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      onTap: () => _onTap(context, ref),
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
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: route.color, fontWeight: FontWeight.w800),
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
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '~${route.estimatedTravelMinutes} min',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.history_rounded, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, WidgetRef ref) async {
    await ref.read(favoritesNotifierProvider.notifier).touchRecent(route.id);
    if (context.mounted) {
      context.push(RoutePaths.trackingFor(route.id));
    }
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_outline_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No saved routes yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tap the bookmark icon on any route card\nto save it for quick access later.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => context.go(RoutePaths.home),
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Browse Routes'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
