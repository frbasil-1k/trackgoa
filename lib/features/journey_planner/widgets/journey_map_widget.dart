import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../tracking/services/map_tile_service.dart';
import '../models/journey_leg.dart';
import '../models/journey_option.dart';

/// Interactive map visualization for a planned transit journey.
///
/// Features clean, distinct visual treatments for:
/// - Walking legs (subtle dashed/muted lines)
/// - Transit legs (high-contrast vibrant route polylines)
/// - Transfer interchanges (prominent transfer badge)
/// - Origin and Destination pins
class JourneyMapWidget extends StatefulWidget {
  const JourneyMapWidget({
    super.key,
    required this.journey,
    this.height = 240.0,
  });

  final JourneyOption journey;
  final double height;

  @override
  State<JourneyMapWidget> createState() => _JourneyMapWidgetState();
}

class _JourneyMapWidgetState extends State<JourneyMapWidget> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLngBounds _calculateBounds() {
    final points = <LatLng>[
      widget.journey.origin.coordinate,
      widget.journey.destination.coordinate,
    ];

    for (final leg in widget.journey.legs) {
      points.add(leg.fromCoordinate);
      points.add(leg.toCoordinate);
      points.addAll(leg.polylinePoints);
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bounds = _calculateBounds();

    final polylines = <Polyline>[];
    final markers = <Marker>[];

    // Build polylines and markers for each leg
    for (int i = 0; i < widget.journey.legs.length; i++) {
      final leg = widget.journey.legs[i];

      if (leg.isWalking) {
        // Walking leg: subtle dashed/muted grey line
        polylines.add(
          Polyline(
            points: leg.polylinePoints.isNotEmpty
                ? leg.polylinePoints
                : [leg.fromCoordinate, leg.toCoordinate],
            color: const Color(0xFF607D8B).withValues(alpha: 0.70),
            strokeWidth: 3.5,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),
        );
      } else {
        // Transit leg: Hero route color with crisp white casing
        final routeColor = leg.route?.color ?? AppColors.primary;
        final poly = leg.polylinePoints.isNotEmpty
            ? leg.polylinePoints
            : [leg.fromCoordinate, leg.toCoordinate];

        // Casing
        polylines.add(
          Polyline(
            points: poly,
            color: Colors.white,
            strokeWidth: 7.0,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),
        );
        // Core
        polylines.add(
          Polyline(
            points: poly,
            color: routeColor,
            strokeWidth: 4.5,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),
        );
      }

      // Transfer Point Marker
      if (leg.legType == JourneyLegType.transferWalk) {
        markers.add(
          Marker(
            point: leg.fromCoordinate,
            width: 38,
            height: 38,
            alignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00897B), width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.sync_alt_rounded,
                  size: 20,
                  color: Color(0xFF00897B),
                ),
              ),
            ),
          ),
        );
      }
    }

    // Origin Marker
    markers.add(
      Marker(
        point: widget.journey.origin.coordinate,
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF00897B),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.my_location_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );

    // Distinct Transit Alighting Stop Marker (if different from actual destination)
    final alightingStop = widget.journey.alightingStop;
    if (alightingStop != null) {
      final isDistinct = (alightingStop.coordinates.latitude -
                  widget.journey.destination.coordinate.latitude)
              .abs() >
          0.0002 ||
          (alightingStop.coordinates.longitude -
                  widget.journey.destination.coordinate.longitude)
              .abs() >
          0.0002;

      if (isDistinct) {
        markers.add(
          Marker(
            point: alightingStop.coordinates,
            width: 38,
            height: 38,
            alignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.directions_bus_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      }
    }

    // Actual Destination Marker
    markers.add(
      Marker(
        point: widget.journey.destination.coordinate,
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x44000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: widget.height,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(36),
            ),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            MapTileService.buildTileLayer(),
            PolylineLayer(polylines: polylines),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }
}
