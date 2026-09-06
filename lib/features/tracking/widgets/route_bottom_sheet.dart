import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/shared/widgets/app_card.dart';
import '../../../core/shared/widgets/live_badge.dart';
import '../../../core/shared/widgets/status_pill.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/alert_model.dart';
import '../../../data/models/route_model.dart';
import '../../../data/models/stop_model.dart';
import '../providers/eta_providers.dart';
import '../services/eta_calculation_service.dart';
import '../services/live_alert_service.dart';

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
class RouteBottomSheet extends ConsumerStatefulWidget {
  const RouteBottomSheet({
    required this.route,
    required this.dragNotifier,
    super.key,
  });

  final RouteModel route;
  final DragStateNotifier dragNotifier;

  @override
  ConsumerState<RouteBottomSheet> createState() => _RouteBottomSheetState();
}

class _RouteBottomSheetState extends ConsumerState<RouteBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _dragController;
  double _dragPosition = 0.0;
  late final LiveAlertService _alertService;

  @override
  void initState() {
    super.initState();
    _dragController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 0.0,
    );
    _alertService = LiveAlertService(
      onAlert: _showAlertSnackbar,
    );
  }

  @override
  void dispose() {
    _dragController.dispose();
    _alertService.reset();
    super.dispose();
  }

  void _showAlertSnackbar(AlertModel alert) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _alertIcon(alert.type),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                alert.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _alertColor(alert.type),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
        ),
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          320,
        ),
      ),
    );
  }

  IconData _alertIcon(AlertType type) {
    switch (type) {
      case AlertType.twoStopsAway:
        return Icons.notifications_active_outlined;
      case AlertType.oneStopAway:
        return Icons.directions_bus_rounded;
      case AlertType.reached:
        return Icons.check_circle_outline;
      case AlertType.delayed:
        return Icons.access_time;
      case AlertType.slowdown:
        return Icons.warning_amber_outlined;
    }
  }

  Color _alertColor(AlertType type) {
    switch (type) {
      case AlertType.twoStopsAway:
        return AppColors.primary;
      case AlertType.oneStopAway:
        return AppColors.accent;
      case AlertType.reached:
        return AppColors.success;
      case AlertType.delayed:
        return AppColors.warning;
      case AlertType.slowdown:
        return AppColors.warning;
    }
  }

  void _onVerticalDragStart(DragStartDetails details) {
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

    // Listen to live stops progress and fire alerts on threshold crossings.
    ref.listen<AsyncValue<List<StopProgress>>>(
      liveStopsProvider(widget.route.id),
      (_, next) {
        final stops = next.value;
        if (stops == null || stops.isEmpty) return;
        final selectedStopId = ref.read(selectedStopIdProvider(widget.route.id));
        _alertService.processStopsProgress(
          routeId: widget.route.id,
          selectedStopId: selectedStopId,
          stopsProgress: stops,
        );
      },
    );

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
          child: _PanelContent(
            route: widget.route,
            onSelectStop: (stopId) {
              ref.read(selectedStopIdProvider(widget.route.id).notifier).state = stopId;
              _alertService.resetForStop(stopId);
            },
          ),
        ),
      ),
    );
  }
}

class _PanelContent extends ConsumerWidget {
  const _PanelContent({
    required this.route,
    required this.onSelectStop,
  });

  final RouteModel route;
  final ValueChanged<String> onSelectStop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              _LiveEtaCard(routeId: route.id),
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
                routeId: route.id,
                stops: route.stops,
                routeColor: route.color,
                onSelectStop: onSelectStop,
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

/// Live ETA card showing next stop, ETA, speed, and stops remaining.
///
/// Watches [routeProgressSummaryProvider] for live updates.
class _LiveEtaCard extends ConsumerWidget {
  const _LiveEtaCard({required this.routeId});

  final String routeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(routeProgressSummaryProvider(routeId));

    final summary = summaryAsync.value;

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
              Icons.directions_bus_rounded,
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
                  summary?.nextStopName ?? 'Waiting for bus…',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _LiveMetricChip(
                      icon: Icons.timer_outlined,
                      label: summary?.nextStopEtaLabel ?? '—',
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _LiveMetricChip(
                      icon: Icons.speed_rounded,
                      label: summary?.speedLabel ?? '—',
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _LiveMetricChip(
                      icon: Icons.location_on_outlined,
                      label: summary == null
                          ? '—'
                          : '${summary.stopsRemaining} left',
                      color: AppColors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const StatusPill(
            label: 'Live',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _LiveMetricChip extends StatelessWidget {
  const _LiveMetricChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
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

class _StopsTimelineList extends ConsumerWidget {
  const _StopsTimelineList({
    required this.routeId,
    required this.stops,
    required this.routeColor,
    required this.onSelectStop,
  });

  final String routeId;
  final List<StopModel> stops;
  final Color routeColor;
  final ValueChanged<String> onSelectStop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stopsAsync = ref.watch(liveStopsProvider(routeId));
    final liveStops = stopsAsync.value;
    // Build a lookup: stopId -> StopProgress for the live state.
    final progressById = <String, StopProgress>{};
    if (liveStops != null) {
      for (final sp in liveStops) {
        progressById[sp.stop.id] = sp;
      }
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stops.length,
      itemBuilder: (context, index) {
        final stop = stops[index];
        final isFirst = index == 0;
        final isLast = index == stops.length - 1;
        final progress = progressById[stop.id];

        return _StopTimelineItem(
          stop: stop,
          isFirst: isFirst,
          isLast: isLast,
          routeColor: routeColor,
          progress: progress,
          onTap: () => onSelectStop(stop.id),
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
    required this.progress,
    required this.onTap,
  });

  final StopModel stop;
  final bool isFirst;
  final bool isLast;
  final Color routeColor;
  final StopProgress? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final state = progress?.state ?? StopProgressState.upcoming;
    final isPassed = state == StopProgressState.passed;
    final isCurrent = state == StopProgressState.current;
    final isUpcoming = state == StopProgressState.upcoming;

    final dotColor = isPassed
        ? AppColors.inactive
        : (isCurrent ? routeColor : routeColor.withValues(alpha: 0.45));
    final dotBorderColor = isPassed ? AppColors.inactive : routeColor;
    final lineColor = isPassed
        ? AppColors.inactive.withValues(alpha: 0.35)
        : AppColors.outline;
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: isCurrent
              ? FontWeight.w700
              : (isFirst || isLast
                  ? FontWeight.w600
                  : (isPassed ? FontWeight.w400 : FontWeight.normal)),
          color: isPassed
              ? AppColors.textSecondary.withValues(alpha: 0.6)
              : (isCurrent
                  ? AppColors.textPrimary
                  : AppColors.textPrimary),
          decoration: isPassed ? TextDecoration.lineThrough : null,
        );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: SizedBox(
          height: 56,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!isFirst)
                      Positioned(
                        top: 0,
                        child: Container(
                          width: 2,
                          height: 28,
                          color: lineColor,
                        ),
                      ),
                    if (isCurrent)
                      Positioned(
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: routeColor.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    Container(
                      width: isFirst || isLast || isCurrent ? 14 : 10,
                      height: isFirst || isLast || isCurrent ? 14 : 10,
                      decoration: BoxDecoration(
                        color: isPassed ? AppColors.inactive : dotColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrent
                              ? routeColor
                              : (isFirst || isLast
                                  ? Colors.white
                                  : dotBorderColor),
                          width: isCurrent ? 3 : 2,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Positioned(
                        bottom: 0,
                        child: Container(
                          width: 2,
                          height: 28,
                          color: lineColor,
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
                        style: textStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isFirst)
                      const StatusPill(
                        label: 'Origin',
                        color: AppColors.primary,
                      )
                    else if (isLast)
                      const StatusPill(
                        label: 'Destination',
                        color: AppColors.accent,
                      )
                    else if (isCurrent)
                      StatusPill(
                        label: progress?.etaLabel ?? 'Here',
                        color: AppColors.success,
                      )
                    else if (isUpcoming && progress != null)
                      StatusPill(
                        label: progress!.etaLabel,
                        color: AppColors.primary,
                      )
                    else if (isPassed)
                      const StatusPill(
                        label: 'Passed',
                        color: AppColors.inactive,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
