import 'package:flutter/foundation.dart';
import '../../../data/models/route_model.dart';
import '../../../data/models/stop_model.dart';

/// Represents an evaluated candidate transit access stop for an arbitrary destination.
@immutable
class TransitAccessStop implements Comparable<TransitAccessStop> {
  const TransitAccessStop({
    required this.stop,
    required this.route,
    required this.walkingDistanceMeters,
    required this.walkingMinutes,
    required this.suitabilityScore,
    required this.explanation,
  });

  /// The verified GTFS transit stop.
  final StopModel stop;

  /// The route serving this stop.
  final RouteModel route;

  /// Walking distance in meters from this stop to the actual passenger destination.
  final double walkingDistanceMeters;

  /// Estimated walking time in minutes.
  final int walkingMinutes;

  /// Composite score (higher is better) based on walking proximity, route directness,
  /// and hub connectivity.
  final double suitabilityScore;

  /// Human-readable explanation of why this stop was selected.
  final String explanation;

  @override
  int compareTo(TransitAccessStop other) {
    // Primary sort: higher suitability score first
    return other.suitabilityScore.compareTo(suitabilityScore);
  }

  @override
  bool operator ==(Object other) =>
      other is TransitAccessStop &&
      stop.id == other.stop.id &&
      route.id == other.route.id &&
      walkingDistanceMeters == other.walkingDistanceMeters;

  @override
  int get hashCode => Object.hash(stop.id, route.id, walkingDistanceMeters);
}
