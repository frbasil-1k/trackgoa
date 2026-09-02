import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/shared/widgets/app_card.dart';
import '../../../core/shared/widgets/live_badge.dart';
import '../../../core/shared/widgets/status_pill.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/route_model.dart';
import '../../../data/models/stop_model.dart';

/// Google Maps-style sliding panel with smooth dragging and rich route details.
/// Optimized with RepaintBoundary to eliminate drag lag.
class RouteBottomSheet extends StatelessWidget {
  const RouteBottomSheet({
    required this.route,
    super.key,
  });

  final RouteModel route;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return SlidingUpPanel(
      minHeight: screenHeight * 0.20,
      maxHeight: screenHeight * 0.85,
      snapPoint: 0.45,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.sheetRadius),
      ),
      backdropEnabled: false,
      parallaxEnabled: false,
      parallaxOffset: 0.0,
      isDraggable: true,
      renderPanelSheet: true,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 40,
          spreadRadius: 0,
          offset: const Offset(0, -8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, -4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, -2),
        ),
      ],
      panelBuilder: (scrollController) => RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.sheetRadius),
            ),
            border: Border(
              top: BorderSide(
                color: Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
          child: ListView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              // 1. Drag Handle
              const _DragHandle(),

              // 2. Header with Hero Badge
              _BottomSheetHeader(route: route),

              const SizedBox(height: AppSpacing.md),

              // 3. Large Uber-style ETA Highlight Card
              _EtaHighlightCard(
                estimatedTravelMinutes: route.estimatedTravelMinutes,
              ),

              const SizedBox(height: AppSpacing.md),

              // 4. Quick Action Buttons Row
              _ActionButtonsRow(route: route),

              const SizedBox(height: AppSpacing.lg),

              // 5. Route Stops Timeline
              Text(
                'Route Stops',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),

              _StopsTimelineList(
                stops: route.stops,
                routeColor: route.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 5,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.inactive.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomSheetHeader extends StatelessWidget {
  const _BottomSheetHeader({required this.route});

  final RouteModel route;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Hero(
            tag: 'route-${route.id}',
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: route.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                  border: Border.all(
                    color: route.color.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  route.shortName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: route.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${route.origin} → ${route.destination}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const LiveBadge(),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${route.stops.length} stops  •  Every 15 min',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EtaHighlightCard extends StatelessWidget {
  const _EtaHighlightCard({required this.estimatedTravelMinutes});

  final int estimatedTravelMinutes;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.timer_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated Travel Time',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '~$estimatedTravelMinutes',
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 26,
                                ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'mins',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const StatusPill(
              label: 'On Time',
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtonsRow extends StatelessWidget {
  const _ActionButtonsRow({required this.route});

  final RouteModel route;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  context.push(RoutePaths.analyticsFor(route.id)),
              icon: const Icon(Icons.insights_rounded, size: 18),
              label: const Text('Analytics'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.controlRadius),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tracking ${route.shortName} live updates'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.controlRadius),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_active_outlined, size: 18),
              label: const Text('Get Alerts'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.controlRadius),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StopsTimelineList extends StatelessWidget {
  const _StopsTimelineList({
    required this.stops,
    required this.routeColor,
  });

  final List<StopModel> stops;
  final Color routeColor;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        children: stops.asMap().entries.map((entry) {
          final index = entry.key;
          final stop = entry.value;
          final isFirst = index == 0;
          final isLast = index == stops.length - 1;

          return _StopTimelineItem(
            stop: stop,
            isFirst: isFirst,
            isLast: isLast,
            routeColor: routeColor,
          );
        }).toList(),
      ),
    );
  }
}

class _StopTimelineItem extends StatelessWidget {
  const _StopTimelineItem({
    required this.stop,
    required this.isFirst,
    required this.isLast,
    required this.routeColor,
  });

  final StopModel stop;
  final bool isFirst;
  final bool isLast;
  final Color routeColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Vertical line above
                if (!isFirst)
                  Positioned(
                    top: 0,
                    child: Container(
                      width: 2,
                      height: 24,
                      color: AppColors.outline,
                    ),
                  ),
                // Center dot
                Container(
                  width: isFirst || isLast ? 14 : 10,
                  height: isFirst || isLast ? 14 : 10,
                  decoration: BoxDecoration(
                    color: isFirst || isLast ? routeColor : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isFirst || isLast ? Colors.white : routeColor,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: routeColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                // Vertical line below
                if (!isLast)
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 2,
                      height: 24,
                      color: AppColors.outline,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    stop.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: isFirst || isLast
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                  ),
                ),
                if (isFirst)
                  const StatusPill(label: 'Origin', color: AppColors.primary)
                else if (isLast)
                  const StatusPill(label: 'Destination', color: AppColors.accent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
