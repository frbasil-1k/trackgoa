import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// An ordered stop belonging to a transit route.
///
/// Arrival time and passed/current/upcoming state are intentionally derived
/// later from live bus positions rather than stored here.
@immutable
class StopModel {
  const StopModel({
    required this.id,
    required this.name,
    required this.coordinates,
    required this.routeId,
    required this.order,
  });

  final String id;
  final String name;
  final LatLng coordinates;
  final String routeId;
  final int order;

  StopModel copyWith({
    String? id,
    String? name,
    LatLng? coordinates,
    String? routeId,
    int? order,
  }) => StopModel(
    id: id ?? this.id,
    name: name ?? this.name,
    coordinates: coordinates ?? this.coordinates,
    routeId: routeId ?? this.routeId,
    order: order ?? this.order,
  );

  @override
  bool operator ==(Object other) =>
      other is StopModel &&
      id == other.id &&
      name == other.name &&
      coordinates == other.coordinates &&
      routeId == other.routeId &&
      order == other.order;

  @override
  int get hashCode => Object.hash(id, name, coordinates, routeId, order);
}
