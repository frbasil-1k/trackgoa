import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'stop_model.dart';

/// Static route information and road geometry used by discovery and tracking features.
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
    this.city,
    this.gtfsTripId,
    this.headsign,
    this.serviceType,
    this.fareLabel,
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

  /// Optional metadata for transit presentation and filtering.
  final String? city;
  final String? gtfsTripId;
  final String? headsign;
  final String? serviceType;
  final String? fareLabel;

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
    String? city,
    String? gtfsTripId,
    String? headsign,
    String? serviceType,
    String? fareLabel,
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
    city: city ?? this.city,
    gtfsTripId: gtfsTripId ?? this.gtfsTripId,
    headsign: headsign ?? this.headsign,
    serviceType: serviceType ?? this.serviceType,
    fareLabel: fareLabel ?? this.fareLabel,
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
      estimatedTravelMinutes == other.estimatedTravelMinutes &&
      city == other.city &&
      gtfsTripId == other.gtfsTripId &&
      headsign == other.headsign &&
      serviceType == other.serviceType &&
      fareLabel == other.fareLabel;

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
    city,
    gtfsTripId,
    headsign,
    serviceType,
    fareLabel,
  );
}
