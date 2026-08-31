import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Service for Phase 6 bus movement calculations along OSRM polyline coordinates.
///
/// Provides utilities for:
/// - Calculating bearing/heading between GPS coordinates
/// - Finding interpolated position along a polyline by distance
/// - Preparing foundation for smooth bus movement animation
class PolylineNavigationService {
  const PolylineNavigationService();

  /// Calculate bearing (heading) in degrees from point A to point B.
  ///
  /// Returns degrees from 0° (North) to 360° clockwise.
  /// Used to rotate bus marker icon along the route direction.
  double calculateBearing(LatLng from, LatLng to) {
    final lat1 = _toRadians(from.latitude);
    final lat2 = _toRadians(to.latitude);
    final dLon = _toRadians(to.longitude - from.longitude);

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final bearing = math.atan2(y, x);
    return (_toDegrees(bearing) + 360) % 360;
  }

  /// Calculate distance in meters between two GPS coordinates using Haversine formula.
  double calculateDistance(LatLng from, LatLng to) {
    const earthRadiusMeters = 6371000.0;

    final lat1 = _toRadians(from.latitude);
    final lat2 = _toRadians(to.latitude);
    final dLat = _toRadians(to.latitude - from.latitude);
    final dLon = _toRadians(to.longitude - from.longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  /// Find the interpolated position along a polyline at a given distance from the start.
  ///
  /// Returns:
  /// - `position`: The GPS coordinate at the target distance
  /// - `bearing`: The heading in degrees at that position
  /// - `segmentIndex`: The polyline segment containing this position
  ///
  /// Used in Phase 6 to animate bus movement along the real road geometry.
  ({LatLng position, double bearing, int segmentIndex})? interpolateAlongPolyline(
    List<LatLng> polyline,
    double targetDistanceMeters,
  ) {
    if (polyline.isEmpty) return null;
    if (polyline.length == 1) {
      return (
        position: polyline.first,
        bearing: 0.0,
        segmentIndex: 0,
      );
    }

    double accumulatedDistance = 0.0;

    for (int i = 0; i < polyline.length - 1; i++) {
      final start = polyline[i];
      final end = polyline[i + 1];
      final segmentDistance = calculateDistance(start, end);

      if (accumulatedDistance + segmentDistance >= targetDistanceMeters) {
        // Target distance falls within this segment
        final remainingDistance = targetDistanceMeters - accumulatedDistance;
        final fraction = segmentDistance > 0 ? remainingDistance / segmentDistance : 0.0;

        final interpolatedLat =
            start.latitude + (end.latitude - start.latitude) * fraction;
        final interpolatedLon =
            start.longitude + (end.longitude - start.longitude) * fraction;

        final bearing = calculateBearing(start, end);

        return (
          position: LatLng(interpolatedLat, interpolatedLon),
          bearing: bearing,
          segmentIndex: i,
        );
      }

      accumulatedDistance += segmentDistance;
    }

    // Target distance exceeds total polyline length, return last point
    return (
      position: polyline.last,
      bearing: calculateBearing(polyline[polyline.length - 2], polyline.last),
      segmentIndex: polyline.length - 2,
    );
  }

  /// Calculate the total length of a polyline in meters.
  double calculatePolylineLength(List<LatLng> polyline) {
    if (polyline.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < polyline.length - 1; i++) {
      totalDistance += calculateDistance(polyline[i], polyline[i + 1]);
    }

    return totalDistance;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180.0;
  double _toDegrees(double radians) => radians * 180.0 / math.pi;
}
