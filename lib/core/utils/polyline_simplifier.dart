import 'package:latlong2/latlong.dart';

import '../../features/tracking/services/polyline_navigation_service.dart';

/// Utility for simplifying polylines using the Ramer-Douglas-Peucker algorithm.
///
/// Reduces the number of points in a polyline while preserving its shape within
/// a specified tolerance (epsilon). Used to smooth OSRM polylines for rendering
/// without sacrificing road accuracy.
///
/// Example:
/// ```dart
/// final simplified = PolylineSimplifier.simplify(
///   originalPoints,
///   epsilon: 2.5, // 2–3 meters tolerance
/// );
/// ```
class PolylineSimplifier {
  const PolylineSimplifier._();

  static const _nav = PolylineNavigationService();

  /// Simplify a polyline using the Ramer-Douglas-Peucker algorithm.
  ///
  /// Parameters:
  /// - [points]: Original polyline coordinates
  /// - [epsilon]: Maximum perpendicular distance in meters a point can be
  ///   from the simplified line before it must be included
  ///
  /// Returns simplified list of coordinates. Start and end points are always preserved.
  static List<LatLng> simplify(List<LatLng> points, {required double epsilon}) {
    if (points.length <= 2) return List.from(points);

    // Find the point with maximum perpendicular distance from line segment
    double maxDistance = 0.0;
    int maxIndex = 0;
    final start = points.first;
    final end = points.last;

    for (int i = 1; i < points.length - 1; i++) {
      final distance = _perpendicularDistance(points[i], start, end);
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // If max distance is greater than epsilon, recursively simplify
    if (maxDistance > epsilon) {
      // Recursive call on first half
      final firstHalf = simplify(
        points.sublist(0, maxIndex + 1),
        epsilon: epsilon,
      );

      // Recursive call on second half
      final secondHalf = simplify(
        points.sublist(maxIndex),
        epsilon: epsilon,
      );

      // Combine results (remove duplicate middle point)
      return [...firstHalf.sublist(0, firstHalf.length - 1), ...secondHalf];
    } else {
      // All points between start and end can be removed
      return [start, end];
    }
  }

  /// Calculate perpendicular distance from a point to a line segment.
  ///
  /// Uses cross product approach adapted for geographic coordinates.
  static double _perpendicularDistance(
    LatLng point,
    LatLng lineStart,
    LatLng lineEnd,
  ) {
    // If line segment is actually a point
    if (lineStart.latitude == lineEnd.latitude &&
        lineStart.longitude == lineEnd.longitude) {
      return _nav.calculateDistance(point, lineStart);
    }

    // Calculate using cross product formula adapted for GPS coordinates
    final x0 = point.latitude;
    final y0 = point.longitude;
    final x1 = lineStart.latitude;
    final y1 = lineStart.longitude;
    final x2 = lineEnd.latitude;
    final y2 = lineEnd.longitude;

    // Vector from lineStart to lineEnd
    final dx = x2 - x1;
    final dy = y2 - y1;

    // Squared length of line segment
    final lengthSquared = dx * dx + dy * dy;

    if (lengthSquared == 0) {
      return _nav.calculateDistance(point, lineStart);
    }

    // Calculate projection parameter t
    final t = ((x0 - x1) * dx + (y0 - y1) * dy) / lengthSquared;

    // Find closest point on line segment
    final LatLng closestPoint;
    if (t < 0) {
      // Closest to start
      closestPoint = lineStart;
    } else if (t > 1) {
      // Closest to end
      closestPoint = lineEnd;
    } else {
      // On the segment
      closestPoint = LatLng(
        x1 + t * dx,
        y1 + t * dy,
      );
    }

    // Return distance from point to closest point on segment
    return _nav.calculateDistance(point, closestPoint);
  }
}
