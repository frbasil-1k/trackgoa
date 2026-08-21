import 'package:flutter/foundation.dart';

/// Service state displayed independently from a bus's live position.
enum BusServiceState { running, delayed, stopped }

@immutable
class BusStatus {
  const BusStatus({
    required this.busId,
    required this.state,
    required this.delayMinutes,
    required this.lastUpdated,
  });

  final String busId;
  final BusServiceState state;
  final int delayMinutes;
  final DateTime lastUpdated;

  BusStatus copyWith({
    String? busId,
    BusServiceState? state,
    int? delayMinutes,
    DateTime? lastUpdated,
  }) => BusStatus(
    busId: busId ?? this.busId,
    state: state ?? this.state,
    delayMinutes: delayMinutes ?? this.delayMinutes,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );

  @override
  bool operator ==(Object other) =>
      other is BusStatus &&
      busId == other.busId &&
      state == other.state &&
      delayMinutes == other.delayMinutes &&
      lastUpdated == other.lastUpdated;

  @override
  int get hashCode => Object.hash(busId, state, delayMinutes, lastUpdated);
}
