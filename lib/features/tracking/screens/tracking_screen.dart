import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/polyline_simplifier.dart';
import '../../../data/models/bus_position.dart';
import '../../../data/models/route_model.dart';
import '../../../data/repositories/repository_providers.dart';
import '../providers/map_providers.dart';
import '../services/map_tile_service.dart';
import '../widgets/map_controls.dart';
import '../widgets/route_bottom_sheet.dart';
import '../widgets/route_info_card.dart';

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
                  child: _GlassBackButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),

                // 4. Route Info Card
                Positioned(
                  top: MediaQuery.paddingOf(context).top + AppSpacing.xs,
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  child: RouteInfoCard(route: route),
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
        Container(color: AppColors.background),
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
  // Layers are cached once and reused across rebuilds
  late final List<LatLng> _cachedSimplifiedPolyline;
  late final TileLayer _cachedTileLayer;
  late final PolylineLayer _cachedPolylineLayer;
  late final MarkerLayer _cachedMarkerLayer;

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

    _cachedPolylineLayer = PolylineLayer(
      polylines: [
        Polyline(
          points: _cachedSimplifiedPolyline,
          color: widget.route.color,
          strokeWidth: 5.0,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      ],
    );

    _cachedMarkerLayer = MarkerLayer(
      markers: _buildOptimizedMarkers(),
    );
  }

  List<Marker> _buildOptimizedMarkers() {
    return widget.route.stops.asMap().entries.map((entry) {
      final index = entry.key;
      final stop = entry.value;
      final isFirst = index == 0;
      final isLast = index == widget.route.stops.length - 1;

      return Marker(
        point: stop.coordinates,
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: RepaintBoundary(
          child: _PremiumStopMarker(
            stopNumber: index + 1,
            routeColor: widget.route.color,
            isFirst: isFirst,
            isLast: isLast,
          ),
        ),
      );
    }).toList();
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
    if (positions.isEmpty && _currentBusPositions.isEmpty) return;

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
  MarkerLayer _buildBusMarkerLayer() {
    if (_currentBusPositions.isEmpty) {
      return const MarkerLayer(markers: []);
    }

    final markers = <Marker>[];
    for (int i = 0; i < _currentBusPositions.length; i++) {
      final bus = _currentBusPositions[i];
      final interpolated = _interpolateBus(bus);

      markers.add(
        Marker(
          point: interpolated.position,
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: RepaintBoundary(
            child: _BusMarkerWidget(
              headingDegrees: interpolated.heading,
              routeColor: widget.route.color,
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
            RepaintBoundary(child: _cachedPolylineLayer),
            RepaintBoundary(child: _cachedMarkerLayer),
            // Bus markers rebuild on every frame during interpolation, but the
            // RepaintBoundary keeps the repaint isolated from the map layers.
            RepaintBoundary(child: _buildBusMarkerLayer()),
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

/// Premium stop marker with numbers, origin circle, and destination pin.
class _PremiumStopMarker extends StatelessWidget {
  const _PremiumStopMarker({
    required this.stopNumber,
    required this.routeColor,
    required this.isFirst,
    required this.isLast,
  });

  final int stopNumber;
  final Color routeColor;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    if (isFirst) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: routeColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
        ),
      );
    }

    if (isLast) {
      return Icon(
        Icons.location_on,
        color: routeColor,
        size: 32,
      );
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: routeColor,
          width: 2.5,
        ),
      ),
      child: Center(
        child: Text(
          '$stopNumber',
          style: TextStyle(
            color: routeColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// Animated bus marker that rotates to face the travel direction.
class _BusMarkerWidget extends StatelessWidget {
  const _BusMarkerWidget({
    required this.headingDegrees,
    required this.routeColor,
  });

  /// Bus heading in degrees (0° = North, clockwise, matching OSRM bearing convention).
  final double headingDegrees;
  final Color routeColor;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: headingDegrees * math.pi / 180,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: routeColor,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x3D000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.directions_bus_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
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
          color: Colors.white.withValues(alpha: 0.96),
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
            child: const Center(
              child: Icon(
                Icons.arrow_back_rounded,
                size: 24,
                color: Color(0xFF16292D),
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
                AppColors.background,
                AppColors.primaryContainer.withValues(alpha: 0.2),
                AppColors.background,
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
