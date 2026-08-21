import 'package:flutter/foundation.dart';

/// Stable bus metadata; live location and service state are separate models.
@immutable
class BusModel {
  const BusModel({
    required this.id,
    required this.routeId,
    required this.label,
    this.capacity,
    this.vehicleType,
  });

  final String id;
  final String routeId;
  final String label;
  final int? capacity;
  final String? vehicleType;

  BusModel copyWith({
    String? id,
    String? routeId,
    String? label,
    int? capacity,
    String? vehicleType,
  }) => BusModel(
    id: id ?? this.id,
    routeId: routeId ?? this.routeId,
    label: label ?? this.label,
    capacity: capacity ?? this.capacity,
    vehicleType: vehicleType ?? this.vehicleType,
  );

  @override
  bool operator ==(Object other) =>
      other is BusModel &&
      id == other.id &&
      routeId == other.routeId &&
      label == other.label &&
      capacity == other.capacity &&
      vehicleType == other.vehicleType;

  @override
  int get hashCode => Object.hash(id, routeId, label, capacity, vehicleType);
}
