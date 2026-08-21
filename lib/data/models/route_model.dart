import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'stop_model.dart';

/// Static route information and geometry used by route and tracking features.
@immutable
class RouteModel {
  const RouteModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.origin,
    required this.destination,
    required this.stops,
    required this.polylinePoints,
    required this.color,
    required this.estimatedTravelMinutes,
  });

  final String id;
  final String name;
  final String shortName;
  final String origin;
  final String destination;
  final List<StopModel> stops;
  final List<LatLng> polylinePoints;
  final Color color;
  final int estimatedTravelMinutes;

  RouteModel copyWith({
    String? id,
    String? name,
    String? shortName,
    String? origin,
    String? destination,
    List<StopModel>? stops,
    List<LatLng>? polylinePoints,
    Color? color,
    int? estimatedTravelMinutes,
  }) => RouteModel(
    id: id ?? this.id,
    name: name ?? this.name,
    shortName: shortName ?? this.shortName,
    origin: origin ?? this.origin,
    destination: destination ?? this.destination,
    stops: stops ?? this.stops,
    polylinePoints: polylinePoints ?? this.polylinePoints,
    color: color ?? this.color,
    estimatedTravelMinutes:
        estimatedTravelMinutes ?? this.estimatedTravelMinutes,
  );

  @override
  bool operator ==(Object other) =>
      other is RouteModel &&
      id == other.id &&
      name == other.name &&
      shortName == other.shortName &&
      origin == other.origin &&
      destination == other.destination &&
      listEquals(stops, other.stops) &&
      listEquals(polylinePoints, other.polylinePoints) &&
      color == other.color &&
      estimatedTravelMinutes == other.estimatedTravelMinutes;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    shortName,
    origin,
    destination,
    Object.hashAll(stops),
    Object.hashAll(polylinePoints),
    color,
    estimatedTravelMinutes,
  );
}
