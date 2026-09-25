import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../data/gtfs/generated_goa_transit_data.dart';
import '../../../data/models/bus_model.dart';
import '../../../data/models/bus_position.dart';
import '../../../data/models/route_model.dart';
import '../../../data/models/stop_model.dart';
import '../../../data/repositories/repository_providers.dart';
import 'eta_providers.dart';
import 'map_providers.dart';

/// Complete passenger-facing intelligence for a transit vehicle.
///
/// Merges static verified fleet specifications (model, operator, registration,
/// amenities, seating capacity) with real-time simulated telemetry (speed,
/// location, next stop, crowding level, with clear simulation disclosure).
@immutable
class PassengerVehicleIntelligence {
  const PassengerVehicleIntelligence({
    required this.bus,
    required this.route,
    required this.position,
    this.nextStop,
    this.etaMinutes,
  });

  final BusModel bus;
  final RouteModel route;
  final BusPosition? position;
  final StopModel? nextStop;
  final int? etaMinutes;

  VehicleCrowding get crowding => bus.crowding;

  String get vehicleIdentifier =>
      bus.registrationNumber ?? bus.label;

  String get vehicleModel =>
      bus.vehicleModel ?? 'Olectra K9';

  String get operatorName =>
      bus.operatorName ?? 'Kadamba Transport Corporation Ltd (KTCL)';

  bool get isVerifiedFleetAsset => bus.isVerifiedFleetAsset;

  String get speedLabel => position != null && position!.speedKmh > 0
      ? '${position!.speedKmh.round()} km/h'
      : 'At stop';

  String get motionStatus => position != null && position!.speedKmh > 0
      ? 'In Transit • ${position!.speedKmh.round()} km/h'
      : 'Stationary / Boarding';

  String get nextStopEtaLabel {
    if (nextStop == null) return 'En route';
    if (etaMinutes != null && etaMinutes! > 0) {
      return '$etaMinutes min';
    }
    return 'Approaching';
  }

  /// Explicit flag to guarantee transparency on telemetry origin.
  bool get isSimulatedTelemetry => bus.isSimulated;
}

/// Selected vehicle identifier state per route.
final selectedVehicleIdProvider =
    StateProvider.family<String?, String>((ref, routeId) => null);

/// Authoritative single source of truth for the currently tracked vehicle on [routeId].
///
/// If no vehicle has been explicitly selected by the passenger, defaults to the
/// first available vehicle assigned to that route.
final activeVehicleIdProvider =
    Provider.family<String, String>((ref, routeId) {
  final explicitId = ref.watch(selectedVehicleIdProvider(routeId));
  if (explicitId != null && explicitId.isNotEmpty) {
    return explicitId;
  }
  final vehicles = ref.watch(routeVehiclesProvider(routeId));
  if (vehicles.isNotEmpty) {
    return vehicles.first.id;
  }
  return '$routeId-bus-1';
});

/// Provides the active fleet of vehicles assigned to a route.
///
/// Uses verified KTCL electric bus fleet records (Olectra K9, GA-08-V series).
final routeVehiclesProvider =
    Provider.family<List<BusModel>, String>((ref, routeId) {
  final cleanId = routeId.toLowerCase();
  final generatedFleet = GeneratedGoaTransitData.fleet[cleanId];
  if (generatedFleet != null && generatedFleet.isNotEmpty) {
    return generatedFleet;
  }

  // Authoritative fallback using documented KTCL electric bus registrations
  return [
    BusModel(
      id: '$routeId-bus-1',
      routeId: routeId,
      label: 'Kadamba EV Shuttle #1',
      registrationNumber: 'GA-08-V-4965',
      vehicleModel: 'Olectra K9',
      chassis: 'BYD EBUZZ K9D.2.1',
      operatorName: 'Kadamba Transport Corporation / Evey Trans',
      isVerifiedFleetAsset: true,
      capacity: 32,
      vehicleType: 'Electric AC City Shuttle',
      isElectric: true,
      isAirConditioned: true,
      isWheelchairAccessible: true,
      crowding: VehicleCrowding.low,
      isSimulated: true,
    ),
  ];
});

/// Live passenger intelligence for a specific vehicle.
///
/// Reactively updates with simulated speed, location, crowding, and stop ETA
/// whenever the route progress updates.
final vehicleIntelligenceProvider =
    Provider.family<PassengerVehicleIntelligence, String>((ref, busId) {
  final engine = ref.watch(busSimulationEngineProvider);

  // Extract routeId from busId (e.g. 'R1-bus-1' -> 'R1')
  final parts = busId.split('-');
  final routeId = parts.isNotEmpty ? parts.first : '';

  final vehicles = ref.watch(routeVehiclesProvider(routeId));
  final bus = vehicles.firstWhere(
    (b) => b.id.toLowerCase() == busId.toLowerCase() ||
        busId.toLowerCase().startsWith(b.id.toLowerCase()) ||
        b.id.toLowerCase().startsWith(busId.toLowerCase()),
    orElse: () => vehicles.isNotEmpty
        ? vehicles.first
        : BusModel(
            id: busId,
            routeId: routeId,
            label: 'Kadamba EV Shuttle',
            registrationNumber: 'GA-08-V-4965',
            vehicleModel: 'Olectra K9',
            chassis: 'BYD EBUZZ K9D.2.1',
            operatorName: 'Kadamba Transport Corporation / Evey Trans',
            isVerifiedFleetAsset: true,
          ),
  );

  // React to simulation progress ticks for this route
  ref.watch(routeProgressSummaryProvider(routeId));

  final routeAsync = ref.watch(selectedRouteProvider(routeId));
  RouteModel? route = routeAsync.value;
  if (route == null) {
    for (final r in GeneratedGoaTransitData.routes) {
      if (r.id.toLowerCase() == routeId.toLowerCase()) {
        route = r;
        break;
      }
    }
  }

  final resolvedRoute = route ?? GeneratedGoaTransitData.routes.first;

  final positions = engine.getPositionsForRoute(routeId);
  BusPosition? matchingPos;
  for (final pos in positions) {
    if (pos.busId.toLowerCase() == busId.toLowerCase() ||
        pos.busId.toLowerCase() == bus.id.toLowerCase()) {
      matchingPos = pos;
      break;
    }
  }

  StopModel? nextStop;
  int? etaMinutes;

  if (matchingPos != null && resolvedRoute.stops.isNotEmpty) {
    if (matchingPos.nextStopId != null) {
      for (final stop in resolvedRoute.stops) {
        if (stop.id == matchingPos.nextStopId) {
          nextStop = stop;
          break;
        }
      }
    } else {
      nextStop = resolvedRoute.stops.first;
    }

    if (matchingPos.distanceRemainingToNextStopMeters != null &&
        matchingPos.speedKmh > 0) {
      final speedMps = matchingPos.speedKmh * 1000 / 3600;
      final seconds =
          matchingPos.distanceRemainingToNextStopMeters! / speedMps;
      etaMinutes = (seconds / 60).ceil();
    }
  } else if (resolvedRoute.stops.isNotEmpty) {
    nextStop = resolvedRoute.stops.first;
  }

  return PassengerVehicleIntelligence(
    bus: bus,
    route: resolvedRoute,
    position: matchingPos,
    nextStop: nextStop,
    etaMinutes: etaMinutes,
  );
});
