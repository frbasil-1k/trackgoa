import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// Time-stamped live position data for a bus.
@immutable
class BusPosition {
  const BusPosition({
    required this.busId,
    required this.coordinates,
    required this.headingDegrees,
    required this.speedKmh,
    required this.timestamp,
    this.nearestStopId,
    this.nextStopId,
    this.distanceRemainingToNextStopMeters,
  });

  final String busId;
  final LatLng coordinates;
  final double headingDegrees;
  final double speedKmh;
  final DateTime timestamp;
  final String? nearestStopId;
  final String? nextStopId;
  final double? distanceRemainingToNextStopMeters;

  BusPosition copyWith({
    String? busId,
    LatLng? coordinates,
    double? headingDegrees,
    double? speedKmh,
    DateTime? timestamp,
    String? nearestStopId,
    String? nextStopId,
    double? distanceRemainingToNextStopMeters,
  }) => BusPosition(
    busId: busId ?? this.busId,
    coordinates: coordinates ?? this.coordinates,
    headingDegrees: headingDegrees ?? this.headingDegrees,
    speedKmh: speedKmh ?? this.speedKmh,
    timestamp: timestamp ?? this.timestamp,
    nearestStopId: nearestStopId ?? this.nearestStopId,
    nextStopId: nextStopId ?? this.nextStopId,
    distanceRemainingToNextStopMeters:
        distanceRemainingToNextStopMeters ??
        this.distanceRemainingToNextStopMeters,
  );

  @override
  bool operator ==(Object other) =>
      other is BusPosition &&
      busId == other.busId &&
      coordinates == other.coordinates &&
      headingDegrees == other.headingDegrees &&
      speedKmh == other.speedKmh &&
      timestamp == other.timestamp &&
      nearestStopId == other.nearestStopId &&
      nextStopId == other.nextStopId &&
      distanceRemainingToNextStopMeters ==
          other.distanceRemainingToNextStopMeters;

  @override
  int get hashCode => Object.hash(
    busId,
    coordinates,
    headingDegrees,
    speedKmh,
    timestamp,
    nearestStopId,
    nextStopId,
    distanceRemainingToNextStopMeters,
  );
}
