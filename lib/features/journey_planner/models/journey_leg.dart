import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/bus_model.dart';
import '../../../data/models/route_model.dart';
import '../../../data/models/stop_model.dart';

enum JourneyLegType {
  walking,
  transit,
  transferWalk,
}

/// Represents a single stage or leg within a multimodal transit journey.
@immutable
class JourneyLeg {
  const JourneyLeg({
    required this.legType,
    required this.fromName,
    required this.toName,
    required this.fromCoordinate,
    required this.toCoordinate,
    this.route,
    this.recommendedVehicle,
    this.boardingStop,
    this.alightingStop,
    this.intermediateStops = const [],
    required this.durationMinutes,
    required this.distanceMeters,
    this.polylinePoints = const [],
    required this.instructions,
    this.departureTimeEstimate,
    this.arrivalTimeEstimate,
    this.liveVehicleCountdown,
    this.isSimulatedTiming = false,
  });

  final JourneyLegType legType;
  final String fromName;
  final String toName;
  final LatLng fromCoordinate;
  final LatLng toCoordinate;
  final RouteModel? route;
  final BusModel? recommendedVehicle;
  final StopModel? boardingStop;
  final StopModel? alightingStop;
  final List<StopModel> intermediateStops;
  final int durationMinutes;
  final double distanceMeters;
  final List<LatLng> polylinePoints;
  final String instructions;
  final String? departureTimeEstimate;
  final String? arrivalTimeEstimate;
  final String? liveVehicleCountdown;
  final bool isSimulatedTiming;

  bool get isTransit => legType == JourneyLegType.transit;
  bool get isWalking =>
      legType == JourneyLegType.walking || legType == JourneyLegType.transferWalk;
  bool get isTransfer => legType == JourneyLegType.transferWalk;

  int get stopCount => intermediateStops.length + 1;
}
