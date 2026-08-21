import 'package:flutter/foundation.dart';

/// Kinds of rider-facing service events emitted by later alert providers.
enum AlertType { twoStopsAway, oneStopAway, reached, delayed, slowdown }

/// An alert references route entities by id, keeping alert history lightweight.
@immutable
class AlertModel {
  const AlertModel({
    required this.id,
    required this.busId,
    required this.routeId,
    required this.stopId,
    required this.type,
    required this.createdAt,
    required this.message,
  });

  final String id;
  final String busId;
  final String routeId;
  final String stopId;
  final AlertType type;
  final DateTime createdAt;
  final String message;

  AlertModel copyWith({
    String? id,
    String? busId,
    String? routeId,
    String? stopId,
    AlertType? type,
    DateTime? createdAt,
    String? message,
  }) => AlertModel(
    id: id ?? this.id,
    busId: busId ?? this.busId,
    routeId: routeId ?? this.routeId,
    stopId: stopId ?? this.stopId,
    type: type ?? this.type,
    createdAt: createdAt ?? this.createdAt,
    message: message ?? this.message,
  );

  @override
  bool operator ==(Object other) =>
      other is AlertModel &&
      id == other.id &&
      busId == other.busId &&
      routeId == other.routeId &&
      stopId == other.stopId &&
      type == other.type &&
      createdAt == other.createdAt &&
      message == other.message;

  @override
  int get hashCode =>
      Object.hash(id, busId, routeId, stopId, type, createdAt, message);
}
