import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/shared/widgets/app_card.dart';
import '../../../core/shared/widgets/live_badge.dart';
import '../../../core/shared/widgets/status_pill.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/alert_model.dart';
import '../../../data/models/bus_model.dart';
import '../../../data/models/route_model.dart';
import '../../../data/models/stop_model.dart';
import '../providers/eta_providers.dart';
import '../providers/vehicle_providers.dart';
import '../services/eta_calculation_service.dart';
import '../services/live_alert_service.dart';
import 'vehicle_detail_sheet.dart';

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
    )..addListener(() {
        if (mounted) setState(() {});
      });
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
    HapticFeedback.mediumImpact();
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
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
        ),
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          200,
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

  void _toggleExpansion() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_dragPosition > 0.4 || _dragController.value > 0.4) {
        _dragPosition = 0.0;
        _dragController.animateTo(0.0);
      } else {
        _dragPosition = 1.0;
        _dragController.animateTo(1.0);
      }
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final minHeight = (screenHeight * 0.33).clamp(260.0, 310.0);
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
    final minHeight = (screenHeight * 0.33).clamp(260.0, 310.0);
    final maxHeight = screenHeight * 0.85;
    final dragRange = maxHeight - minHeight;

    final currentHeight = minHeight + (_dragPosition * dragRange);

    // Listen to live stops progress and fire alerts on threshold crossings if armed.
    ref.listen<AsyncValue<List<StopProgress>>>(
      liveStopsProvider(widget.route.id),
      (_, next) {
        final stops = next.value;
        if (stops == null || stops.isEmpty) return;
        final alertsEnabled = ref.read(stopAlertEnabledProvider(widget.route.id));
        if (!alertsEnabled) return;

        final selectedStopId = ref.read(selectedStopIdProvider(widget.route.id)) ??
            (widget.route.stops.isNotEmpty ? widget.route.stops.last.id : null);
        _alertService.processStopsProgress(
          routeId: widget.route.id,
          selectedStopId: selectedStopId,
          stopsProgress: stops,
        );
      },
    );

    final isExpanded = _dragPosition > 0.4 || _dragController.value > 0.4;

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
            isExpanded: isExpanded,
            onToggleExpansion: _toggleExpansion,
            onSelectStop: (stopId) {
              ref.read(selectedStopIdProvider(widget.route.id).notifier).state = stopId;
              _alertService.resetForStop(stopId);
              HapticFeedback.selectionClick();
              final stop = widget.route.stops.firstWhere(
                (s) => s.id == stopId,
                orElse: () => widget.route.stops.last,
              );
              final messenger = ScaffoldMessenger.maybeOf(context);
              if (messenger != null) {
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.near_me_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Destination set: ${stop.name}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                    ),
                  ),
                );
              }
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
    required this.isExpanded,
    required this.onToggleExpansion,
    required this.onSelectStop,
  });

  final RouteModel route;
  final bool isExpanded;
  final VoidCallback onToggleExpansion;
  final ValueChanged<String> onSelectStop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _DragHandle(
          onTap: onToggleExpansion,
          isExpanded: isExpanded,
        ),
        Expanded(
          child: ListView(
            key: const ValueKey('tracking-bottom-sheet-list'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              _BottomSheetHeader(route: route),
              const SizedBox(height: AppSpacing.sm),
              _LiveEtaCard(route: route),
              const SizedBox(height: AppSpacing.md),
              _ActionButtonsRow(route: route),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Route Stops',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    'Tap stop to set destination',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                  ),
                ],
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
  const _DragHandle({
    required this.onTap,
    required this.isExpanded,
  });

  final VoidCallback onTap;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final tooltipMessage =
        isExpanded ? 'Collapse route sheet' : 'Expand route sheet';
    return Tooltip(
      message: tooltipMessage,
      child: Semantics(
        label: tooltipMessage,
        button: true,
        child: InkWell(
          key: const ValueKey('bottom-sheet-drag-handle'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.inactive.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 2),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_up_rounded,
                size: 16,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
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
              width: 50,
              height: 50,
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
                '${route.stops.length} verified stops  •  Simulated live demo',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Live ETA card showing bus status, next stop, live metrics,
/// and the passenger's target destination progress and trip progress bar.
class _LiveEtaCard extends ConsumerWidget {
  const _LiveEtaCard({required this.route});

  final RouteModel route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(routeProgressSummaryProvider(route.id));
    final summary = summaryAsync.value;
    final targetProgress = ref.watch(targetStopProgressProvider(route.id));
    final selectedStopId = ref.watch(selectedStopIdProvider(route.id));

    final vehicleId = summary?.busPosition.busId ??
        ref.watch(selectedVehicleIdProvider(route.id)) ??
        '${route.id}-bus-1';
    final intel = ref.watch(vehicleIntelligenceProvider(vehicleId));

    final targetStop = targetProgress?.stop ??
        (route.stops.isNotEmpty ? route.stops.last : null);
    final isCustomTarget = selectedStopId != null &&
        route.stops.isNotEmpty &&
        selectedStopId != route.stops.last.id;

    // Calculate trip progress percentage toward the destination stop
    double progressRatio = 0.0;
    if (summary != null && route.stops.isNotEmpty && targetStop != null) {
      final targetIndex = route.stops.indexWhere((s) => s.id == targetStop.id);
      if (targetIndex > 0) {
        final currentNearestId = summary.busPosition.nearestStopId;
        final nearestIndex =
            route.stops.indexWhere((s) => s.id == currentNearestId);
        if (nearestIndex >= 0) {
          progressRatio = (nearestIndex / targetIndex).clamp(0.0, 1.0);
        }
      }
    }

    final targetState = targetProgress?.state ?? StopProgressState.upcoming;
    final targetStopsAway =
        targetProgress?.stopsAway ?? (route.stops.length - 1);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Tooltip(
                message: 'View vehicle details & occupancy',
                child: Semantics(
                  button: true,
                  label: 'View vehicle details and occupancy',
                  child: InkWell(
                    key: const ValueKey('live-eta-bus-avatar-button'),
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      VehicleDetailSheet.show(
                        context,
                        busId: vehicleId,
                        route: route,
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary?.nextStopName != null
                          ? 'Approaching ${summary!.nextStopName}'
                          : 'Waiting for bus…',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          intel.vehicleIdentifier,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.inactive.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'DEMO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppColors.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            intel.bus.vehicleType ?? 'City Shuttle',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppColors.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          intel.crowding.shortLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: intel.crowding ==
                                    VehicleCrowding.standingRoomOnly
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'View vehicle intelligence',
                child: Semantics(
                  button: true,
                  label: 'View vehicle intelligence',
                  child: InkWell(
                    key: const ValueKey('live-eta-vehicle-sheet-button'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      VehicleDetailSheet.show(
                        context,
                        busId: vehicleId,
                        route: route,
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusPill(
                            label: 'Live',
                            color: AppColors.success,
                          ),
                          SizedBox(width: 3),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (targetStop != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: route.color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                border: Border.all(
                  color: route.color.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCustomTarget
                            ? Icons.near_me_rounded
                            : Icons.flag_rounded,
                        size: 13,
                        color: route.color,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          isCustomTarget
                              ? 'YOUR STOP: ${targetStop.name}'
                              : 'DESTINATION: ${targetStop.name}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: route.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        targetState == StopProgressState.current
                            ? 'Arrived'
                            : (targetState == StopProgressState.passed
                                ? 'Passed'
                                : (targetProgress?.etaLabel ?? '—')),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: targetState == StopProgressState.current
                              ? AppColors.success
                              : (targetState == StopProgressState.passed
                                  ? AppColors.inactive
                                  : AppColors.primary),
                        ),
                      ),
                      if (targetState == StopProgressState.upcoming &&
                          targetStopsAway > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '($targetStopsAway left)',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: targetState == StopProgressState.passed ||
                              targetState == StopProgressState.current
                          ? 1.0
                          : progressRatio,
                      minHeight: 4,
                      backgroundColor:
                          AppColors.inactive.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        targetState == StopProgressState.current
                            ? AppColors.success
                            : route.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

class _ActionButtonsRow extends ConsumerWidget {
  const _ActionButtonsRow({required this.route});

  final RouteModel route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsEnabled = ref.watch(stopAlertEnabledProvider(route.id));
    final targetProgress = ref.watch(targetStopProgressProvider(route.id));
    final summary = ref.watch(routeProgressSummaryProvider(route.id)).value;
    final targetStop = targetProgress?.stop ?? route.stops.last;

    return Row(
      children: [
        // Analytics Button (Preserved for fleet metrics & existing navigation tests)
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
        // Stop Alert Toggle
        Expanded(
          child: alertsEnabled
              ? FilledButton.icon(
                  onPressed: () {
                    ref.read(stopAlertEnabledProvider(route.id).notifier).state =
                        false;
                    HapticFeedback.lightImpact();
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Stop alerts turned off for ${targetStop.name}',
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.controlRadius),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_active_rounded,
                      size: 18),
                  label: const Text('Alerts Active'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.controlRadius),
                    ),
                  ),
                )
              : FilledButton.icon(
                  onPressed: () {
                    // Ensure target stop is tracked
                    final currentSelected =
                        ref.read(selectedStopIdProvider(route.id));
                    if (currentSelected == null) {
                      ref
                          .read(selectedStopIdProvider(route.id).notifier)
                          .state = targetStop.id;
                    }
                    ref.read(stopAlertEnabledProvider(route.id).notifier).state =
                        true;
                    HapticFeedback.mediumImpact();
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          '🔔 Alert armed for ${targetStop.name} (notifying 2 & 1 stop away)',
                        ),
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.controlRadius),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_none_rounded,
                      size: 18),
                  label: const Text('Get Alerts'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.controlRadius),
                    ),
                  ),
                ),
        ),
        const SizedBox(width: AppSpacing.xs),
        // Share Trip Action
        IconButton.outlined(
          tooltip: 'Share Trip',
          onPressed: () {
            final nextStopName = summary?.nextStopName ?? 'En route';
            final nextEta = summary?.nextStopEtaLabel ?? '—';
            final targetEta = targetProgress?.etaLabel ?? '—';
            final shareText =
                'SMART-GO Live • Route ${route.shortName} (${route.origin} → ${route.destination})\n'
                'Next stop: $nextStopName ($nextEta)\n'
                'Heading to: ${targetStop.name} (ETA: $targetEta)';

            Clipboard.setData(ClipboardData(text: shareText));
            HapticFeedback.lightImpact();
            final messenger = ScaffoldMessenger.of(context);
            messenger.clearSnackBars();
            messenger.showSnackBar(
              SnackBar(
                content: const Text('Trip summary copied to clipboard!'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.controlRadius),
                ),
              ),
            );
          },
          icon: const Icon(Icons.share_outlined, size: 18),
          style: IconButton.styleFrom(
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
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
    final selectedStopId = ref.watch(selectedStopIdProvider(routeId));
    final activeTargetId =
        selectedStopId ?? (stops.isNotEmpty ? stops.last.id : null);

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
        final isSelected = stop.id == activeTargetId;

        return _StopTimelineItem(
          stop: stop,
          isFirst: isFirst,
          isLast: isLast,
          isSelected: isSelected,
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
    required this.isSelected,
    required this.routeColor,
    required this.progress,
    required this.onTap,
  });

  final StopModel stop;
  final bool isFirst;
  final bool isLast;
  final bool isSelected;
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
        : (isCurrent
            ? routeColor
            : (isSelected ? routeColor : routeColor.withValues(alpha: 0.45)));
    final dotBorderColor = isPassed ? AppColors.inactive : routeColor;
    final lineColor = isPassed
        ? AppColors.inactive.withValues(alpha: 0.35)
        : AppColors.outline;
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: isCurrent || isSelected
              ? FontWeight.w700
              : (isFirst || isLast
                  ? FontWeight.w600
                  : (isPassed ? FontWeight.w400 : FontWeight.normal)),
          color: isPassed
              ? AppColors.textSecondary.withValues(alpha: 0.6)
              : AppColors.textPrimary,
          decoration: isPassed ? TextDecoration.lineThrough : null,
        );

    return Tooltip(
      message: isSelected
          ? 'Current destination: ${stop.name}'
          : 'Tap to set ${stop.name} as destination',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: isSelected
              ? BoxDecoration(
                  color: routeColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                  border: Border.all(
                    color: routeColor.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                )
              : null,
        child: SizedBox(
          height: 52,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!isFirst)
                      Positioned(
                        top: 0,
                        child: Container(
                          width: 2,
                          height: 26,
                          color: lineColor,
                        ),
                      ),
                    if (isCurrent || isSelected)
                      Positioned(
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? routeColor.withValues(alpha: 0.22)
                                : routeColor.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: routeColor, width: 2)
                                : null,
                          ),
                        ),
                      ),
                    Container(
                      width: isFirst || isLast || isCurrent || isSelected ? 14 : 10,
                      height:
                          isFirst || isLast || isCurrent || isSelected ? 14 : 10,
                      decoration: BoxDecoration(
                        color: isPassed ? AppColors.inactive : dotColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrent || isSelected
                              ? (isSelected ? Colors.white : routeColor)
                              : (isFirst || isLast
                                  ? Colors.white
                                  : dotBorderColor),
                          width: isCurrent || isSelected ? 3 : 2,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Positioned(
                        bottom: 0,
                        child: Container(
                          width: 2,
                          height: 26,
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
                    if (isSelected && !isLast) ...[
                      const StatusPill(
                        label: 'Your Stop',
                        color: AppColors.primary,
                      ),
                      if (isUpcoming && progress != null) ...[
                        const SizedBox(width: 4),
                        StatusPill(
                          label: progress!.etaLabel,
                          color: AppColors.accent,
                        ),
                      ],
                    ] else if (isLast) ...[
                      StatusPill(
                        label: isSelected ? 'Destination' : 'Terminus',
                        color: AppColors.accent,
                      ),
                      if (isUpcoming && progress != null) ...[
                        const SizedBox(width: 4),
                        StatusPill(
                          label: progress!.etaLabel,
                          color: AppColors.primary,
                        ),
                      ],
                    ] else if (isFirst) ...[
                      const StatusPill(
                        label: 'Origin',
                        color: AppColors.primary,
                      ),
                    ] else if (isCurrent) ...[
                      StatusPill(
                        label: progress?.etaLabel ?? 'Here',
                        color: AppColors.success,
                      ),
                    ] else if (isUpcoming && progress != null) ...[
                      StatusPill(
                        label: progress!.etaLabel,
                        color: AppColors.primary,
                      ),
                    ] else if (isPassed) ...[
                      const StatusPill(
                        label: 'Passed',
                        color: AppColors.inactive,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
