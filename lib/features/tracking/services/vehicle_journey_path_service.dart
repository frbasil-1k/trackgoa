import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'polyline_navigation_service.dart';

/// Directional cue located along the active journey path pointing in the direction of travel.
@immutable
class JourneyDirectionalCue {
  const JourneyDirectionalCue({
    required this.position,
    required this.bearingDegrees,
  });

  final LatLng position;
  final double bearingDegrees;

  @override
  bool operator ==(Object other) =>
      other is JourneyDirectionalCue &&
      position == other.position &&
      bearingDegrees == other.bearingDegrees;

  @override
  int get hashCode => Object.hash(position, bearingDegrees);
}

/// Dynamic segments of a transit route partitioned from the perspective of the
/// selected vehicle and passenger destination.
@immutable
class VehicleJourneySegments {
  const VehicleJourneySegments({
    required this.basePolyline,
    required this.passedPolyline,
    required this.activeJourneyPolyline,
    required this.remainingPolyline,
    required this.directionalCues,
  });

  /// The entire simplified route corridor (used as a subtle background trace).
  final List<LatLng> basePolyline;

  /// Road geometry already traversed by the selected vehicle (subdued).
  final List<LatLng> passedPolyline;

  /// High-priority active path leading from the selected vehicle forward to
  /// the passenger's selected destination (or route terminus).
  final List<LatLng> activeJourneyPolyline;

  /// Road geometry beyond the passenger's destination to the end of the route (subdued).
  final List<LatLng> remainingPolyline;

  /// Spaced directional arrows along the active journey pointing forward.
  final List<JourneyDirectionalCue> directionalCues;
}

/// Service that computes vehicle-centric journey visualization on the map.
///
/// Ensures the passenger's currently selected vehicle is the primary visual
/// source of truth:
/// - Passed geometry is subdued.
/// - Active path from selected vehicle to destination is high-contrast & primary.
/// - Direction of travel is reinforced with subtle chevrons along the active path.
/// - Secondary vehicles do not compete with duplicate bright paths.
class VehicleJourneyPathService {
  const VehicleJourneyPathService();

  static const PolylineNavigationService _nav = PolylineNavigationService();

  /// Computes partitioned journey segments for [routePolyline] based on [busLocation]
  /// and [destinationLocation].
  VehicleJourneySegments computeJourneySegments({
    required List<LatLng> routePolyline,
    required LatLng? busLocation,
    required LatLng? destinationLocation,
    required bool isLoopRoute,
    double chevronSpacingMeters = 450.0,
  }) {
    if (routePolyline.isEmpty) {
      return const VehicleJourneySegments(
        basePolyline: [],
        passedPolyline: [],
        activeJourneyPolyline: [],
        remainingPolyline: [],
        directionalCues: [],
      );
    }

    if (busLocation == null) {
      return VehicleJourneySegments(
        basePolyline: routePolyline,
        passedPolyline: const [],
        activeJourneyPolyline: routePolyline,
        remainingPolyline: const [],
        directionalCues: _generateDirectionalCues(routePolyline, chevronSpacingMeters),
      );
    }

    final busIndex = _findNearestIndex(routePolyline, busLocation);
    final destIndex = destinationLocation != null
        ? _findNearestIndex(routePolyline, destinationLocation)
        : routePolyline.length - 1;

    final passed = <LatLng>[];
    final active = <LatLng>[];
    final remaining = <LatLng>[];

    if (isLoopRoute) {
      // Loop route: bus travels continuously around the loop (start -> end/start)
      if (busIndex <= destIndex) {
        // Standard in-lap segment
        passed.addAll(routePolyline.sublist(0, busIndex + 1));
        if (passed.isEmpty || passed.last != busLocation) {
          passed.add(busLocation);
        }
        active.add(busLocation);
        if (busIndex + 1 <= destIndex) {
          active.addAll(routePolyline.sublist(busIndex + 1, destIndex + 1));
        }
        if (destIndex < routePolyline.length) {
          remaining.addAll(routePolyline.sublist(destIndex));
        }
      } else {
        // Loop wrap: bus is at later vertex and destination is on the next lap
        passed.addAll(routePolyline.sublist(destIndex, busIndex + 1));
        if (passed.isEmpty || passed.last != busLocation) {
          passed.add(busLocation);
        }
        active.add(busLocation);
        active.addAll(routePolyline.sublist(busIndex + 1));
        active.addAll(routePolyline.sublist(0, destIndex + 1));
      }
    } else {
      // Linear corridor route (Origin -> Destination)
      if (busIndex <= destIndex) {
        passed.addAll(routePolyline.sublist(0, busIndex + 1));
        if (passed.isEmpty || passed.last != busLocation) {
          passed.add(busLocation);
        }
        active.add(busLocation);
        if (busIndex + 1 <= destIndex) {
          active.addAll(routePolyline.sublist(busIndex + 1, destIndex + 1));
        }
        if (destIndex < routePolyline.length) {
          remaining.addAll(routePolyline.sublist(destIndex));
        }
      } else {
        // Bus has already passed destination stop (mismatch scenario)
        passed.addAll(routePolyline.sublist(0, busIndex + 1));
        if (passed.isEmpty || passed.last != busLocation) {
          passed.add(busLocation);
        }
        active.add(busLocation);
        if (busIndex + 1 < routePolyline.length) {
          active.addAll(routePolyline.sublist(busIndex + 1));
        }
      }
    }

    final cues = _generateDirectionalCues(active, chevronSpacingMeters);

    return VehicleJourneySegments(
      basePolyline: routePolyline,
      passedPolyline: passed,
      activeJourneyPolyline: active,
      remainingPolyline: remaining,
      directionalCues: cues,
    );
  }

  int _findNearestIndex(List<LatLng> polyline, LatLng target) {
    if (polyline.isEmpty) return 0;
    int bestIdx = 0;
    double bestDist = double.infinity;

    for (int i = 0; i < polyline.length; i++) {
      final d = _nav.calculateDistance(polyline[i], target);
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  List<JourneyDirectionalCue> _generateDirectionalCues(
    List<LatLng> activePath,
    double spacingMeters,
  ) {
    if (activePath.length < 2) return const [];

    final cues = <JourneyDirectionalCue>[];
    double accumulated = 0.0;
    const maxChevrons = 6;

    for (int i = 0; i < activePath.length - 1; i++) {
      final start = activePath[i];
      final end = activePath[i + 1];
      final segDist = _nav.calculateDistance(start, end);
      accumulated += segDist;

      if (accumulated >= spacingMeters) {
        final bearing = _nav.calculateBearing(start, end);
        cues.add(JourneyDirectionalCue(
          position: end,
          bearingDegrees: bearing,
        ));
        accumulated = 0.0;
        if (cues.length >= maxChevrons) break;
      }
    }

    return cues;
  }
}
