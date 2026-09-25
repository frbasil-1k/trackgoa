import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/polyline_simplifier.dart';
import '../../../data/models/bus_model.dart';
import '../../../data/models/bus_position.dart';
import '../../../data/models/route_model.dart';
import '../../../data/models/stop_model.dart';
import '../../../data/repositories/repository_providers.dart';
import '../providers/eta_providers.dart';
import '../providers/map_providers.dart';
import '../providers/vehicle_providers.dart';
import '../services/eta_calculation_service.dart';
import '../services/map_tile_service.dart';
import '../services/vehicle_journey_path_service.dart';
import '../widgets/map_controls.dart';
import '../widgets/route_bottom_sheet.dart';
import '../widgets/route_info_card.dart';
import '../widgets/vehicle_detail_sheet.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../journey_planner/models/journey_session.dart';
import '../../journey_planner/providers/journey_planner_providers.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({required this.routeId, super.key});

  final String routeId;

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _skeletonFadeAnimation;
  late DragStateNotifier _dragNotifier;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _dragNotifier = DragStateNotifier();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _skeletonFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Sync selected vehicle and destination from active journey session if present
    final activeSession = ref.read(activeJourneySessionProvider);
    if (activeSession != null) {
      if (activeSession.currentVehicleId != null) {
        Future.microtask(() {
          ref.read(selectedVehicleIdProvider(widget.routeId).notifier).state =
              activeSession.currentVehicleId;
        });
      }
      final alightingId = activeSession.currentLeg.alightingStop?.id;
      if (alightingId != null) {
        Future.microtask(() {
          ref.read(selectedStopIdProvider(widget.routeId).notifier).state =
              alightingId;
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _dragNotifier.dispose();
    super.dispose();
  }

  void _onMapReady() {
    if (!_isMapReady && mounted) {
      setState(() {
        _isMapReady = true;
      });
      _fadeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeAsync = ref.watch(selectedRouteProvider(widget.routeId));
    final mapController = ref.watch(mapControllerProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: routeAsync.when(
          data: (route) {
            if (route == null) {
              return _buildErrorState();
            }

            // Record this route as recently viewed.
            Future.microtask(() => ref
                .read(favoritesNotifierProvider.notifier)
                .touchRecent(widget.routeId));

            final allPoints = [
              ...route.polylinePoints,
              ...route.stops.map((s) => s.coordinates),
            ];
            final bounds = LatLngBounds.fromPoints(allPoints);

            return Stack(
              children: [
                // 1. Single FlutterMap instance with shared RepaintBoundary
                // No widget toggling on drag — only IgnorePointer + interaction options
                Positioned.fill(
                  child: _FreezeableMapView(
                    key: ValueKey('map-${widget.routeId}'),
                    route: route,
                    bounds: bounds,
                    mapController: mapController,
                    dragNotifier: _dragNotifier,
                    onMapReady: _onMapReady,
                  ),
                ),

                // 2. Loading Skeleton
                if (!_fadeController.isCompleted)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: _isMapReady,
                      child: FadeTransition(
                        opacity: _skeletonFadeAnimation,
                        child: _MapLoadingSkeleton(),
                      ),
                    ),
                  ),

                // 3. Top Navigation
                Positioned(
                  top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
                  left: AppSpacing.md,
                  child: Tooltip(
                    message: 'Back to routes',
                    child: _GlassBackButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),

                // 4. Route Info Card (offset past back button to prevent touch collision)
                Positioned(
                  top: MediaQuery.paddingOf(context).top + AppSpacing.xs,
                  left: 76,
                  right: AppSpacing.md,
                  child: RouteInfoCard(route: route),
                ),

                // 4b. Active Multimodal Journey Banner
                if (ref.watch(activeJourneySessionProvider) != null)
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 64,
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    child: _ActiveJourneyTrackingBanner(
                      session: ref.watch(activeJourneySessionProvider)!,
                      currentRoute: route,
                      onSwitchToNextLeg: () {
                        final session = ref.read(activeJourneySessionProvider);
                        if (session != null) {
                          final nextLeg = session.nextTransitLeg;
                          if (nextLeg != null && nextLeg.route != null) {
                            ref.read(activeJourneySessionProvider.notifier).advanceToNextLeg();
                            context.go(RoutePaths.trackingFor(nextLeg.route!.id));
                          }
                        }
                      },
                      onCancelJourney: () {
                        ref.read(activeJourneySessionProvider.notifier).cancelJourney();
                      },
                    ),
                  ),

                // 4b. Simulation Paused Indicator
                if (!ref.watch(demoSimulationEnabledProvider))
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 56,
                    left: 76,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16292D).withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x24000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pause_circle_outline_rounded, color: Color(0xFFFBBF24), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Simulation Paused in Settings',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 5. Map Controls
                MapControls(
                  mapController: mapController,
                  onCenterRoute: () {
                    mapController.fitCamera(
                      CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.fromLTRB(56, 80, 56, 260),
                      ),
                    );
                  },
                  onCenterBus: () {
                    final positions = ref.read(busSimulationEngineProvider).getPositionsForRoute(widget.routeId);
                    if (positions.isNotEmpty) {
                      mapController.move(
                        positions.first.coordinates,
                        math.max(mapController.camera.zoom, 14.5),
                      );
                    }
                  },
                ),

                // 6. Bottom Sheet with drag detection
                RouteBottomSheet(
                  route: route,
                  dragNotifier: _dragNotifier,
                ),
              ],
            );
          },
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Stack(
      children: [
        Container(color: Theme.of(context).scaffoldBackgroundColor),
        _MapLoadingSkeleton(),
      ],
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      appBar: AppBar(title: const Text('Route Not Found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.danger,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Unable to load route',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'This route may not exist or is temporarily unavailable.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Map view with freeze capability during drag.
///
/// Phase 5.12 optimization: a single FlutterMap instance is reused.
/// During drag the widget tree is **not** rebuilt — only an [IgnorePointer]
/// is layered on top to absorb bottom-sheet gestures. This eliminates the
/// costly `MapControllerImpl.options = ...` reassignment (which previously
/// triggered `MapInteractiveViewerState.updateGestures` and a full map
/// rebuild on every drag start/end).
class _FreezeableMapView extends ConsumerStatefulWidget {
  const _FreezeableMapView({
    required this.route,
    required this.bounds,
    required this.mapController,
    required this.dragNotifier,
    required this.onMapReady,
    super.key,
  });

  final RouteModel route;
  final LatLngBounds bounds;
  final MapController mapController;
  final DragStateNotifier dragNotifier;
  final VoidCallback onMapReady;

  @override
  ConsumerState<_FreezeableMapView> createState() => _FreezeableMapViewState();
}

class _FreezeableMapViewState extends ConsumerState<_FreezeableMapView>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  // Layers are cached and partitioned based on active journey context
  late final List<LatLng> _cachedSimplifiedPolyline;
  late final TileLayer _cachedTileLayer;

  static const _journeyPathService = VehicleJourneyPathService();
  VehicleJourneySegments? _cachedSegments;
  String? _lastSegmentsBusId;
  String? _lastSegmentsTargetStopId;
  LatLng? _lastSegmentsBusCoord;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeCachedLayers();
    _initializeBusAnimation();
  }

  @override
  void didUpdateWidget(_FreezeableMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route.id != widget.route.id) {
      _cachedSegments = null;
      _initializeCachedLayers();
    }
  }

  @override
  void dispose() {
    _disposeBusAnimation();
    super.dispose();
  }

  void _initializeCachedLayers() {
    // Simplify polyline ONCE from raw OSRM coordinates with 2-3m epsilon
    _cachedSimplifiedPolyline = PolylineSimplifier.simplify(
      widget.route.polylinePoints,
      epsilon: 2.5,
    );

    _cachedTileLayer = MapTileService.buildTileLayer();
  }

  VehicleJourneySegments _getJourneySegments({
    required String activeVehicleId,
    required String? selectedStopId,
    required LatLng? activeBusCoord,
  }) {
    final effectiveTargetId = selectedStopId ??
        (widget.route.stops.isNotEmpty ? widget.route.stops.last.id : null);

    if (_cachedSegments != null &&
        _lastSegmentsBusId == activeVehicleId &&
        _lastSegmentsTargetStopId == effectiveTargetId &&
        _lastSegmentsBusCoord == activeBusCoord) {
      return _cachedSegments!;
    }

    StopModel? targetStop;
    if (effectiveTargetId != null) {
      for (final s in widget.route.stops) {
        if (s.id == effectiveTargetId) {
          targetStop = s;
          break;
        }
      }
    }
    targetStop ??=
        widget.route.stops.isNotEmpty ? widget.route.stops.last : null;

    final isLoop = widget.route.origin.toLowerCase() ==
            widget.route.destination.toLowerCase() ||
        (widget.route.stops.isNotEmpty &&
            widget.route.stops.first.id == widget.route.stops.last.id);

    final segments = _journeyPathService.computeJourneySegments(
      routePolyline: _cachedSimplifiedPolyline,
      busLocation: activeBusCoord,
      destinationLocation: targetStop?.coordinates,
      isLoopRoute: isLoop,
    );

    _cachedSegments = segments;
    _lastSegmentsBusId = activeVehicleId;
    _lastSegmentsTargetStopId = effectiveTargetId;
    _lastSegmentsBusCoord = activeBusCoord;
    return segments;
  }

  /// Builds the vehicle-centric journey polyline layer.
  ///
  /// The active vehicle's journey from current location to the passenger's
  /// destination is rendered with primary high-contrast emphasis.
  /// Passed segments and remaining paths are rendered subdued.
  /// Non-selected vehicles do NOT draw competing paths.
  PolylineLayer _buildJourneyPolylineLayer(VehicleJourneySegments segments) {
    final hasActiveTracking = segments.passedPolyline.isNotEmpty ||
        segments.activeJourneyPolyline.isNotEmpty;

    return PolylineLayer(
      polylines: [
        // 1. Fallback base route corridor: ONLY drawn if no active vehicle journey segments exist
        if (!hasActiveTracking && segments.basePolyline.isNotEmpty) ...[
          Polyline(
            points: segments.basePolyline,
            color: Colors.white,
            strokeWidth: 6.0,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),
          Polyline(
            points: segments.basePolyline,
            color: widget.route.color.withValues(alpha: 0.70),
            strokeWidth: 3.8,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),
        ],

        // 2. Passed segment (behind selected bus): Subdued, single continuous path
        if (hasActiveTracking && segments.passedPolyline.isNotEmpty) ...[
          Polyline(
            points: segments.passedPolyline,
            color: Colors.white.withValues(alpha: 0.50),
            strokeWidth: 5.0,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),
          Polyline(
            points: segments.passedPolyline,
            color: widget.route.color.withValues(alpha: 0.32),
            strokeWidth: 3.0,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),
        ],

        // 3. Remaining segment (past passenger destination): Subdued
        if (hasActiveTracking && segments.remainingPolyline.isNotEmpty) ...[
          Polyline(
            points: segments.remainingPolyline,
            color: Colors.white.withValues(alpha: 0.50),
            strokeWidth: 5.0,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),
          Polyline(
            points: segments.remainingPolyline,
            color: widget.route.color.withValues(alpha: 0.32),
            strokeWidth: 3.0,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),
        ],

        // 4. ACTIVE JOURNEY PATH (Selected bus -> Your destination): HERO VISUAL
        if (hasActiveTracking && segments.activeJourneyPolyline.isNotEmpty) ...[
          Polyline(
            points: segments.activeJourneyPolyline,
            color: Colors.white,
            strokeWidth: 7.5,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),
          Polyline(
            points: segments.activeJourneyPolyline,
            color: widget.route.color,
            strokeWidth: 4.8,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),
        ],
      ],
    );
  }

  /// Builds subtle directional chevrons along the active journey path pointing forward.
  MarkerLayer _buildDirectionalChevronsLayer(
    List<JourneyDirectionalCue> cues,
  ) {
    return MarkerLayer(
      markers: cues.map((cue) {
        return Marker(
          point: cue.position,
          width: 18,
          height: 18,
          alignment: Alignment.center,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: cue.bearingDegrees * math.pi / 180,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.navigation_rounded,
                    size: 9,
                    color: widget.route.color,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  MarkerLayer _buildStopMarkerLayer(
    List<StopProgress>? liveStops,
    String? selectedStopId,
  ) {
    final effectiveTargetId = selectedStopId ??
        (widget.route.stops.isNotEmpty ? widget.route.stops.last.id : null);

    final progressMap = <String, StopProgress>{};
    if (liveStops != null) {
      for (final sp in liveStops) {
        progressMap[sp.stop.id] = sp;
      }
    }

    final markers = <Marker>[];
    for (int i = 0; i < widget.route.stops.length; i++) {
      final stop = widget.route.stops[i];
      final isFirst = i == 0;
      final isLast = i == widget.route.stops.length - 1;
      final isDestination = stop.id == effectiveTargetId;
      final sp = progressMap[stop.id];
      final state = sp?.state ?? StopProgressState.upcoming;

      final markerWidth = isDestination ? 72.0 : (state == StopProgressState.current ? 36.0 : 28.0);
      final markerHeight = isDestination ? 68.0 : (state == StopProgressState.current ? 36.0 : 28.0);

      markers.add(
        Marker(
          point: stop.coordinates,
          width: markerWidth,
          height: markerHeight,
          alignment: Alignment.center,
          child: RepaintBoundary(
            child: _TransitStopMarker(
              stop: stop,
              stopNumber: i + 1,
              routeColor: widget.route.color,
              isFirst: isFirst,
              isLast: isLast,
              isSelectedDestination: isDestination,
              state: state,
              onTap: () => _handleStopSelected(stop),
            ),
          ),
        ),
      );
    }

    return MarkerLayer(markers: markers);
  }

  void _handleStopSelected(StopModel stop) {
    final settings = ref.read(settingsNotifierProvider);
    if (settings.vibrationEnabled) {
      HapticFeedback.selectionClick();
    }
    ref.read(selectedStopIdProvider(widget.route.id).notifier).state = stop.id;
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
  }

  // ─── Bus Animation State ──────────────────────────────────────────────────

  /// Interval between the simulation engine's position snapshots (ms).
  /// Used to normalise interpolation progress across frame rates.
  static const _tickIntervalMs = 500;

  late Ticker _busTicker;
  StreamSubscription<List<BusPosition>>? _busPositionsSubscription;

  /// Current display snapshot — the visual position we are interpolating toward.
  final List<BusPosition> _currentBusPositions = [];

  /// Previous snapshot — the anchor point for the current interpolation.
  final List<BusPosition> _previousBusPositions = [];

  /// Progress 0.0 → 1.0 within the current tick window.
  double _interpolationProgress = 1.0;

  /// Wall-clock time (in microseconds) when the last snapshot arrived.
  /// Used to advance the interpolation between ticker frames.
  int? _lastSnapshotMicros;

  /// Initialises the ticker and subscribes to the engine's broadcast stream.
  void _initializeBusAnimation() {
    _busTicker = createTicker(_onBusTick);
    _busTicker.start();

    // Subscribe to the global engine stream and filter for this route.
    final engine = ref.read(busSimulationEngineProvider);
    engine.startRoute(widget.route);
    final initialPositions = engine.getPositionsForRoute(widget.route.id);
    if (initialPositions.isNotEmpty) {
      _currentBusPositions.addAll(initialPositions);
    }

    final routeId = widget.route.id;
    _busPositionsSubscription = engine.positionsStream.listen((allPositions) {
      _onBusPositionsReceived(
        allPositions
            .where((p) => p.busId.startsWith('$routeId-'))
            .toList(growable: false),
      );
    });
  }

  /// Disposes ticker and subscription. Called before super.dispose().
  void _disposeBusAnimation() {
    _busPositionsSubscription?.cancel();
    _busPositionsSubscription = null;
    if (_busTicker.isActive) {
      _busTicker.stop();
    }
    _busTicker.dispose();
  }

  /// Called whenever the simulation engine emits a new position snapshot.
  void _onBusPositionsReceived(List<BusPosition> positions) {
    if (positions.isEmpty) return;

    _previousBusPositions
      ..clear()
      ..addAll(_currentBusPositions);
    _currentBusPositions
      ..clear()
      ..addAll(positions);
    _interpolationProgress = 0.0;
    _lastSnapshotMicros = DateTime.now().microsecondsSinceEpoch;
  }

  /// Per-frame ticker callback. Advances interpolation progress and rebuilds
  /// only the bus marker layer via setState — the map itself is untouched.
  void _onBusTick(Duration elapsed) {
    final simulationEnabled = ref.read(demoSimulationEnabledProvider);
    if (!simulationEnabled) return;
    if (_interpolationProgress >= 1.0) return;

    if (_lastSnapshotMicros != null) {
      final nowMicros = DateTime.now().microsecondsSinceEpoch;
      final elapsedMs = (nowMicros - _lastSnapshotMicros!) / 1000.0;
      _interpolationProgress =
          (elapsedMs / _tickIntervalMs).clamp(0.0, 1.0);
    } else {
      _interpolationProgress = 1.0;
    }

    setState(() {
      // setState only rebuilds this widget — the FlutterMap children
      // list changes only via the MarkerLayer rebuild below, not the map.
    });
  }

  /// Returns the interpolated position for [bus] at the current progress.
  ({LatLng position, double heading}) _interpolateBus(BusPosition bus) {
    // Find the previous snapshot for the same busId (anchor).
    BusPosition? prev;
    for (final p in _previousBusPositions) {
      if (p.busId == bus.busId) {
        prev = p;
        break;
      }
    }

    final from = prev?.coordinates ?? bus.coordinates;
    final to = bus.coordinates;

    // Ease-in-out cubic curve for smooth acceleration and deceleration.
    final t = _easeInOutCubic(_interpolationProgress);

    // Linear interpolation between lat/lng.
    final position = LatLng(
      from.latitude + (to.latitude - from.latitude) * t,
      from.longitude + (to.longitude - from.longitude) * t,
    );

    // Interpolate heading along the shortest angular path.
    final heading = _interpolateHeading(
      prev?.headingDegrees ?? bus.headingDegrees,
      bus.headingDegrees,
      t,
    );

    return (position: position, heading: heading);
  }

  double _easeInOutCubic(double t) {
    return t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;
  }

  /// Interpolates between two angles (0–360°) along the shortest arc.
  double _interpolateHeading(double from, double to, double t) {
    double delta = (to - from) % 360;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    return (from + delta * t) % 360;
  }

  /// Builds the animated bus marker layer for the current route.
  MarkerLayer _buildBusMarkerLayer({bool isLowBandwidth = false}) {
    if (_currentBusPositions.isEmpty) {
      return const MarkerLayer(markers: []);
    }

    final activeVehicleId =
        ref.watch(activeVehicleIdProvider(widget.route.id));

    final markers = <Marker>[];
    for (int i = 0; i < _currentBusPositions.length; i++) {
      final bus = _currentBusPositions[i];
      final interpolated = _interpolateBus(bus);
      final isSelected =
          activeVehicleId.toLowerCase() == bus.busId.toLowerCase();

      markers.add(
        Marker(
          point: interpolated.position,
          width: isSelected ? 58 : 46,
          height: isSelected ? 58 : 46,
          alignment: Alignment.center,
          child: RepaintBoundary(
            child: _BusMarkerWidget(
              busId: bus.busId,
              headingDegrees: interpolated.heading,
              routeColor: widget.route.color,
              isSelected: isSelected,
              isLowBandwidth: isLowBandwidth,
              onTap: () {
                final wasAlreadySelected = isSelected;
                ref
                    .read(selectedVehicleIdProvider(widget.route.id).notifier)
                    .state = bus.busId;
                final settings = ref.read(settingsNotifierProvider);
                if (settings.vibrationEnabled) {
                  HapticFeedback.selectionClick();
                }

                // Recenter map camera onto the tapped vehicle
                widget.mapController.move(
                  interpolated.position,
                  math.max(widget.mapController.camera.zoom, 14.5),
                );

                if (!wasAlreadySelected) {
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  if (messenger != null) {
                    final fleet =
                        ref.read(routeVehiclesProvider(widget.route.id));
                    final matchedBus = fleet.firstWhere(
                      (b) => b.id.toLowerCase() == bus.busId.toLowerCase(),
                      orElse: () => BusModel(
                        id: bus.busId,
                        routeId: widget.route.id,
                        label: bus.busId,
                      ),
                    );
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.directions_bus_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tracking switched to ${matchedBus.registrationNumber ?? matchedBus.label}',
                                style:
                                    const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }
                } else {
                  // If already selected, open the deep vehicle intelligence sheet
                  VehicleDetailSheet.show(
                    context,
                    busId: bus.busId,
                    route: widget.route,
                    onFocusVehicleOnMap: () {
                      widget.mapController.move(
                        interpolated.position,
                        math.max(widget.mapController.camera.zoom, 14.5),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ),
      );
    }

    return MarkerLayer(markers: markers);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final liveStops = ref.watch(liveStopsProvider(widget.route.id)).value;
    final selectedStopId = ref.watch(selectedStopIdProvider(widget.route.id));
    final activeVehicleId = ref.watch(activeVehicleIdProvider(widget.route.id));
    final isLowBandwidth = ref.watch(lowBandwidthModeProvider);

    // Find current coordinate of active vehicle
    LatLng? activeBusCoord;
    for (final pos in _currentBusPositions) {
      if (pos.busId.toLowerCase() == activeVehicleId.toLowerCase()) {
        activeBusCoord = _interpolateBus(pos).position;
        break;
      }
    }

    final segments = _getJourneySegments(
      activeVehicleId: activeVehicleId,
      selectedStopId: selectedStopId,
      activeBusCoord: activeBusCoord,
    );

    // Smoothly recenter camera when tracked vehicle switches
    ref.listen<String>(
      activeVehicleIdProvider(widget.route.id),
      (prev, next) {
        if (prev != null && prev.toLowerCase() != next.toLowerCase()) {
          for (final pos in _currentBusPositions) {
            if (pos.busId.toLowerCase() == next.toLowerCase()) {
              final interpolated = _interpolateBus(pos);
              widget.mapController.move(
                interpolated.position,
                math.max(widget.mapController.camera.zoom, 14.5),
              );
              break;
            }
          }
        }
      },
    );

    // Single FlutterMap instance — never toggled between two configurations.
    // A separate IgnorePointer overlay absorbs bottom-sheet gestures so the
    // map itself never sees them, avoiding any map repaint during drag.
    return RepaintBoundary(
      child: _DragAbsorbingOverlay(
        isDragging: widget.dragNotifier,
        child: FlutterMap(
          mapController: widget.mapController,
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: widget.bounds,
              padding: const EdgeInsets.fromLTRB(56, 80, 56, 260),
            ),
            minZoom: 10.0,
            maxZoom: 18.0,
            onMapReady: widget.onMapReady,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            keepAlive: true,
          ),
          children: [
            // Each layer wrapped in its own RepaintBoundary so the map's
            // repaint region can be split — only the dirty layer repaints.
            RepaintBoundary(child: _cachedTileLayer),
            RepaintBoundary(
              child: _buildJourneyPolylineLayer(segments),
            ),
            if (segments.directionalCues.isNotEmpty)
              RepaintBoundary(
                child: _buildDirectionalChevronsLayer(segments.directionalCues),
              ),
            RepaintBoundary(
              child: _buildStopMarkerLayer(liveStops, selectedStopId),
            ),
            // Bus markers rebuild on every frame during interpolation, but the
            // RepaintBoundary keeps the repaint isolated from the map layers.
            RepaintBoundary(
              child: _buildBusMarkerLayer(isLowBandwidth: isLowBandwidth),
            ),
          ],
        ),
      ),
    );
  }
}

/// A transparent overlay that absorbs pointer events while the bottom sheet
/// is being dragged. Built around [ListenableBuilder] so it only rebuilds the
/// overlay (a no-op `IgnorePointer`) and not the expensive [FlutterMap] tree
/// beneath.
class _DragAbsorbingOverlay extends StatelessWidget {
  const _DragAbsorbingOverlay({
    required this.isDragging,
    required this.child,
  });

  final DragStateNotifier isDragging;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: isDragging,
      builder: (context, child) {
        final dragging = isDragging.isDragging;
        // While the bottom sheet is being dragged, place a transparent
        // absorbing layer over the map. The map underneath does not
        // receive any pointer events and therefore does not repaint.
        if (!dragging) return child!;
        return Stack(
          children: [
            child!,
            const Positioned.fill(
              child: IgnorePointer(
                child: SizedBox.expand(),
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }
}

/// Dynamic transit stop marker with 5-tier visual hierarchy:
/// - Destination: Strongest emphasis with destination pin badge & "YOUR STOP" label
/// - Approaching/Current: Emphasized with ambient aura ring
/// - Passed: Subdued small slate pip
/// - Origin: Terminal concentric circle
/// - Upcoming: Clean crisp transit pip
///
/// Fully interactive: tapping any stop selects it as the destination with instant feedback.
class _TransitStopMarker extends StatelessWidget {
  const _TransitStopMarker({
    required this.stop,
    required this.stopNumber,
    required this.routeColor,
    required this.isFirst,
    required this.isLast,
    required this.isSelectedDestination,
    required this.state,
    required this.onTap,
  });

  final StopModel stop;
  final int stopNumber;
  final Color routeColor;
  final bool isFirst;
  final bool isLast;
  final bool isSelectedDestination;
  final StopProgressState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Tooltip(
        message: isSelectedDestination
            ? 'Your destination: ${stop.name}'
            : '${stop.name} (Stop #$stopNumber) • Tap to set as destination',
        child: Semantics(
          button: true,
          label: isSelectedDestination
              ? 'Destination ${stop.name}'
              : 'Stop #$stopNumber ${stop.name}',
          child: _buildMarkerContent(context),
        ),
      ),
    );
  }

  Widget _buildMarkerContent(BuildContext context) {
    // 1. Destination marker (Strongest passenger focus!)
    if (isSelectedDestination) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF16292D),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'YOUR STOP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: routeColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: routeColor.withValues(alpha: 0.45),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.near_me_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      );
    }

    // 2. Approaching / Current stop
    if (state == StopProgressState.current) {
      return Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: routeColor.withValues(alpha: 0.22),
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: routeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 3. Passed stop
    if (state == StopProgressState.passed) {
      return Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF94A3B8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
        ),
      );
    }

    // 4. Origin stop
    if (isFirst) {
      return Center(
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: routeColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      );
    }

    // 5. Upcoming intermediate stop
    return Center(
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: routeColor, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated vehicle marker with directional heading, subtle live halo,
/// and clear demo telemetry disclosure.
class _BusMarkerWidget extends StatelessWidget {
  const _BusMarkerWidget({
    required this.busId,
    required this.headingDegrees,
    required this.routeColor,
    required this.onTap,
    this.isSelected = false,
    this.isLowBandwidth = false,
  });

  final String busId;
  final double headingDegrees;
  final Color routeColor;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isLowBandwidth;

  @override
  Widget build(BuildContext context) {
    final size = isSelected ? 56.0 : 44.0;
    final haloSize = isSelected ? 54.0 : 42.0;
    final bodySize = isSelected ? 38.0 : 28.0;
    final iconSize = isSelected ? 20.0 : 15.0;
    final arrowWidth = isSelected ? 12.0 : 8.0;
    final arrowHeight = isSelected ? 8.0 : 5.0;

    return Tooltip(
      message: isSelected
          ? 'Active Vehicle $busId (Simulated GPS)'
          : 'Secondary Vehicle $busId • Tap to switch tracking',
      child: Semantics(
        button: true,
        label: isSelected
            ? 'Active Vehicle $busId (Simulated GPS)'
            : 'Secondary Vehicle $busId, tap to switch tracking',
        child: GestureDetector(
          key: ValueKey('bus-marker-$busId'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Subtle live motion halo
                  if (!isLowBandwidth)
                    Container(
                      width: haloSize,
                      height: haloSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: routeColor.withValues(alpha: isSelected ? 0.35 : 0.12),
                        border: Border.all(
                          color: routeColor.withValues(alpha: isSelected ? 0.6 : 0.25),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                    ),

                  // 2. Rotated vehicle indicator (heading pointer + bus icon)
                  Transform.rotate(
                    angle: headingDegrees * math.pi / 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Directional pointer nose
                        Positioned(
                          top: 0,
                          child: ClipPath(
                            clipper: _ArrowClipper(),
                            child: Container(
                              width: arrowWidth,
                              height: arrowHeight,
                              color: isSelected ? routeColor : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        // Bus circle body
                        Container(
                          width: bodySize,
                          height: bodySize,
                          decoration: BoxDecoration(
                            color: isSelected ? routeColor : const Color(0xFF64748B),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: isSelected ? 2.5 : 2.0,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x3D000000),
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.directions_bus_rounded,
                              color: Colors.white,
                              size: iconSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Status pill at bottom center
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16292D),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x2A000000),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        isSelected ? 'LIVE' : 'BUS',
                        style: const TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(_ArrowClipper oldClipper) => false;
}

class _GlassBackButton extends StatefulWidget {
  const _GlassBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_GlassBackButton> createState() => _GlassBackButtonState();
}

class _GlassBackButtonState extends State<_GlassBackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            customBorder: const CircleBorder(),
            splashColor: Colors.black.withValues(alpha: 0.05),
            highlightColor: Colors.black.withValues(alpha: 0.03),
            child: Center(
              child: Icon(
                Icons.arrow_back_rounded,
                size: 24,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapLoadingSkeleton extends StatefulWidget {
  @override
  State<_MapLoadingSkeleton> createState() => _MapLoadingSkeletonState();
}

class _MapLoadingSkeletonState extends State<_MapLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final progress = _shimmerController.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                Theme.of(context).scaffoldBackgroundColor,
              ],
              stops: [
                (progress - 0.3).clamp(0.0, 1.0),
                progress.clamp(0.0, 1.0),
                (progress + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.controlRadius),
                  ),
                  child: Text(
                    'Loading map...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Floating banner displayed when an active passenger journey session is in progress.
class _ActiveJourneyTrackingBanner extends StatelessWidget {
  const _ActiveJourneyTrackingBanner({
    required this.session,
    required this.currentRoute,
    required this.onSwitchToNextLeg,
    required this.onCancelJourney,
  });

  final ActiveJourneySession session;
  final RouteModel currentRoute;
  final VoidCallback onSwitchToNextLeg;
  final VoidCallback onCancelJourney;

  @override
  Widget build(BuildContext context) {
    final nextLeg = session.nextTransitLeg;
    final isTransferNext = nextLeg != null;
    final totalTransitLegs =
        session.journey.legs.where((l) => l.isTransit).length;

    return Container(
      key: const ValueKey('active-journey-tracking-banner'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16292D).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF00897B), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'LEG ${session.currentLegIndex + 1} OF $totalTransitLegs',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Final: ${session.finalDestination.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: onCancelJourney,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close_rounded,
                      size: 16, color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.arrow_forward_rounded,
                  size: 14, color: Color(0xFF80CBC4)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isTransferNext
                      ? 'Transfer at ${session.currentLeg.toName} for ${nextLeg.route?.shortName ?? 'Next Bus'}'
                      : (session.journey.alightingStop != null &&
                              session.journey.alightingStop!.name.toLowerCase() !=
                                  session.finalDestination.name.toLowerCase()
                          ? 'Alight at ${session.journey.alightingStop!.name} • Walk to ${session.finalDestination.name}'
                          : 'Heading to ${session.finalDestination.name} (${session.currentLeg.toName})'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE0F2F1),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isTransferNext) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onSwitchToNextLeg();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Next Bus',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700)),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios_rounded, size: 9),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

