import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/shared/widgets/app_card.dart';
import '../../../core/shared/widgets/live_badge.dart';
import '../../../core/shared/widgets/status_pill.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/route_model.dart';
import '../../../data/models/stop_model.dart';

/// Drag state notifier for map freeze coordination
class DragStateNotifier extends ChangeNotifier {
  bool _isDragging = false;

  bool get isDragging => _isDragging;

  void setDragging(bool dragging) {
    if (_isDragging != dragging) {
      _isDragging = dragging;
      notifyListeners();
    }
  }
}

/// Native Flutter bottom sheet with drag detection for map freeze.
class RouteBottomSheet extends StatefulWidget {
  const RouteBottomSheet({
    required this.route,
    required this.dragNotifier,
    super.key,
  });

  final RouteModel route;
  final DragStateNotifier dragNotifier;

  @override
  State<RouteBottomSheet> createState() => _RouteBottomSheetState();
}

class _RouteBottomSheetState extends State<RouteBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _dragController;
  double _dragPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _dragController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 0.0,
    );
  }

  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }

  void _onVerticalDragStart(DragStartDetails details) {
    // Notify map to freeze rendering
    widget.dragNotifier.setDragging(true);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final minHeight = screenHeight * 0.20;
    final maxHeight = screenHeight * 0.85;
    final dragRange = maxHeight - minHeight;

    setState(() {
      _dragPosition = (_dragPosition - details.delta.dy / dragRange).clamp(0.0, 1.0);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    // Notify map to resume rendering
    widget.dragNotifier.setDragging(false);

    final velocity = details.primaryVelocity ?? 0;

    if (velocity.abs() > 500) {
      if (velocity < 0) {
        _dragController.animateTo(1.0);
      } else {
        _dragController.animateTo(0.0);
      }
    } else {
      if (_dragPosition > 0.5) {
        _dragController.animateTo(1.0);
      } else {
        _dragController.animateTo(0.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final minHeight = screenHeight * 0.20;
    final maxHeight = screenHeight * 0.85;
    final dragRange = maxHeight - minHeight;

    final currentHeight = minHeight + (_dragPosition * dragRange);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: AnimatedBuilder(
          animation: _dragController,
          builder: (context, child) {
            final animatedPosition = _dragController.value;
            final animatedHeight = minHeight + (animatedPosition * dragRange);

            return Container(
              height: _dragController.isAnimating ? animatedHeight : currentHeight,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.sheetRadius),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 16,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: _PanelContent(route: widget.route),
        ),
      ),
    );
  }
}

class _PanelContent extends StatelessWidget {
  const _PanelContent({required this.route});

  final RouteModel route;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _DragHandle(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              _BottomSheetHeader(route: route),
              const SizedBox(height: AppSpacing.md),
              _EtaHighlightCard(
                estimatedTravelMinutes: route.estimatedTravelMinutes,
              ),
              const SizedBox(height: AppSpacing.md),
              _ActionButtonsRow(route: route),
              const SizedBox(height: AppSpacing.lg),
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
      ],
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
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.inactive.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(2.5),
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
    return Row(
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
    );
  }
}

class _EtaHighlightCard extends StatelessWidget {
  const _EtaHighlightCard({required this.estimatedTravelMinutes});

  final int estimatedTravelMinutes;

  @override
  Widget build(BuildContext context) {
    return AppCard(
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
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 26,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'mins',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
    );
  }
}

class _ActionButtonsRow extends StatelessWidget {
  const _ActionButtonsRow({required this.route});

  final RouteModel route;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push(RoutePaths.analyticsFor(route.id)),
            icon: const Icon(Icons.insights_rounded, size: 18),
            label: const Text('Analytics'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
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
                    borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
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
                borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
              ),
            ),
          ),
        ),
      ],
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
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stops.length,
      itemBuilder: (context, index) {
        final stop = stops[index];
        final isFirst = index == 0;
        final isLast = index == stops.length - 1;

        return _StopTimelineItem(
          stop: stop,
          isFirst: isFirst,
          isLast: isLast,
          routeColor: routeColor,
        );
      },
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
                if (!isFirst)
                  Positioned(
                    top: 0,
                    child: Container(
                      width: 2,
                      height: 24,
                      color: AppColors.outline,
                    ),
                  ),
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
                  ),
                ),
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
