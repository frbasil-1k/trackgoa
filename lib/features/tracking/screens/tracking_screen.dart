import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/route_model.dart';
import '../providers/map_providers.dart';
import '../services/map_tile_service.dart';
import '../widgets/map_controls.dart';
import '../widgets/route_bottom_sheet.dart';
import '../widgets/route_info_card.dart';
import '../widgets/stop_marker_widget.dart';

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
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
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

            // Calculate bounds containing all polylines and stops
            final allPoints = [
              ...route.polylinePoints,
              ...route.stops.map((s) => s.coordinates),
            ];
            final bounds = LatLngBounds.fromPoints(allPoints);

            return Stack(
              children: [
                // 1. Isolated Full-Screen Map behind a RepaintBoundary
                Positioned.fill(
                  child: _IsolatedMapView(
                    route: route,
                    routeId: widget.routeId,
                    bounds: bounds,
                    mapController: mapController,
                    onMapReady: _onMapReady,
                  ),
                ),

                // 2. Loading Skeleton Overlay that smoothly fades out when map tiles are ready
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

                // 3. Top Floating Navigation
                Positioned(
                  top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
                  left: AppSpacing.md,
                  child: _GlassBackButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),

                // 4. Floating Route Info Card
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
                    // Fit bounds with generous 56px horizontal padding and bottom sheet clearance
                    mapController.fitCamera(
                      CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.fromLTRB(56, 80, 56, 260),
                      ),
                    );
                  },
                ),

                // 6. Sliding Bottom Sheet with isolated rebuild scope
                RouteBottomSheet(route: route),
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

/// Independent, isolated map widget wrapped in RepaintBoundary
/// to prevent rasterization or rebuilding while the bottom sheet scrolls.
class _IsolatedMapView extends ConsumerWidget {
  const _IsolatedMapView({
    required this.route,
    required this.routeId,
    required this.bounds,
    required this.mapController,
    required this.onMapReady,
  });

  final RouteModel route;
  final String routeId;
  final LatLngBounds bounds;
  final MapController mapController;
  final VoidCallback onMapReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final simplifiedPolyline = ref.watch(simplifiedPolylineProvider(routeId));

    return RepaintBoundary(
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCameraFit: CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.fromLTRB(56, 80, 56, 260),
          ),
          minZoom: 10.0,
          maxZoom: 18.0,
          onMapReady: onMapReady,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
        ),
        children: [
          // OpenStreetMap Caching Tile Layer
          MapTileService.buildTileLayer(),

          // Dual-Layer Route Polyline: Background Glow (~9px) + Main Line (~5px)
          // Uses simplified polyline for smoother rendering
          PolylineLayer(
            polylines: [
              // Background glow layer (wider, soft opacity)
              Polyline(
                points: simplifiedPolyline,
                color: route.color.withValues(alpha: 0.22),
                strokeWidth: 9.0,
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
              // Main route line
              Polyline(
                points: simplifiedPolyline,
                color: route.color,
                strokeWidth: 5.0,
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
            ],
          ),

          // Google Maps-Styled Stop Markers
          MarkerLayer(
            markers: route.stops.asMap().entries.map((entry) {
              final index = entry.key;
              final stop = entry.value;

              return Marker(
                point: stop.coordinates,
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 150 + (index * 40)),
                  curve: Curves.easeOut,
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: value,
                      child: child,
                    ),
                  ),
                  child: StopMarkerWidget(
                    stopNumber: index + 1,
                    routeColor: route.color,
                    isFirst: index == 0,
                    isLast: index == route.stops.length - 1,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// 52x52 Glass-style Circular Back Button with Soft Shadow and Pressed Animation
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
          boxShadow: [
            // Soft primary shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            // Subtle depth shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
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
