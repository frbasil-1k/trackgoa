import 'package:flutter/foundation.dart';

import '../../../data/models/stop_model.dart';
import 'journey_leg.dart';
import 'journey_location.dart';

/// Represents a complete, actionable journey itinerary from origin to destination.
@immutable
class JourneyOption implements Comparable<JourneyOption> {
  const JourneyOption({
    required this.id,
    required this.origin,
    required this.destination,
    required this.legs,
    required this.totalDurationMinutes,
    required this.transferCount,
    required this.walkingMinutes,
    this.waitingMinutes = 0,
    required this.departureTime,
    required this.arrivalTime,
    this.hasLiveVehicle = false,
    this.liveVehicleLabel,
    this.liveVehicleId,
    required this.epistemicStatus,
    this.fareLabel,
  });

  final String id;
  final JourneyLocation origin;
  final JourneyLocation destination;
  final List<JourneyLeg> legs;
  final int totalDurationMinutes;
  final int transferCount;
  final int walkingMinutes;
  final int waitingMinutes;
  final String departureTime;
  final String arrivalTime;
  final bool hasLiveVehicle;
  final String? liveVehicleLabel;
  final String? liveVehicleId;
  final String epistemicStatus;
  final String? fareLabel;

  /// The primary transit leg that the user will board first.
  JourneyLeg? get firstTransitLeg {
    for (final leg in legs) {
      if (leg.isTransit) return leg;
    }
    return null;
  }

  /// Whether this option is a direct bus journey without transfers.
  bool get isDirect => transferCount == 0;

  /// Short summary label like "DIRECT" or "1 TRANSFER".
  String get categoryLabel {
    if (transferCount == 0) return 'DIRECT';
    if (transferCount == 1) return '1 TRANSFER';
    return '$transferCount TRANSFERS';
  }

  /// The recommended transit alighting stop where the passenger should get off the bus.
  StopModel? get alightingStop {
    for (int i = legs.length - 1; i >= 0; i--) {
      if (legs[i].isTransit && legs[i].alightingStop != null) {
        return legs[i].alightingStop;
      }
    }
    return null;
  }

  /// Final walking leg from transit alighting stop to the actual passenger destination (if any).
  JourneyLeg? get finalWalkingLeg {
    if (legs.isNotEmpty && legs.last.isWalking && legs.length > 1) {
      return legs.last;
    }
    return null;
  }

  @override
  int compareTo(JourneyOption other) {
    if (transferCount != other.transferCount) {
      return transferCount.compareTo(other.transferCount);
    }
    return totalDurationMinutes.compareTo(other.totalDurationMinutes);
  }
}
