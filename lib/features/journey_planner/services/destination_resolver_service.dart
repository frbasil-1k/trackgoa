import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/route_model.dart';
import '../models/journey_location.dart';
import '../models/transit_access_stop.dart';
import 'geocoding_service.dart';

/// Intelligent destination resolution engine that bridges arbitrary passenger
/// destinations to the verified transit stop network.
///
/// Pipeline:
/// 1. Local-first search (verified GTFS stops, hubs, landmarks)
/// 2. External place resolution (OpenStreetMap / geocoding with caching)
/// 3. Transit access stop discovery (evaluates proximity, directness, and walk time)
class DestinationResolverService {
  DestinationResolverService({
    GeocodingService? geocodingService,
  }) : _geocodingService = geocodingService ?? GeocodingService();

  final GeocodingService _geocodingService;

  static const double _walkingSpeedMetersPerMinute = 75.0; // ~4.5 km/h
  static const double defaultMaxWalkRadiusMeters = 1400.0;

  /// Haversine distance in meters between two coordinates.
  double calculateDistance(LatLng p1, LatLng p2) {
    const r = 6371000.0;
    final dLat = (p2.latitude - p1.latitude) * math.pi / 180.0;
    final dLon = (p2.longitude - p1.longitude) * math.pi / 180.0;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(p1.latitude * math.pi / 180.0) *
            math.cos(p2.latitude * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  /// Searches for places matching [query] using local GTFS data first,
  /// followed by external geocoding resolution if required.
  Future<List<JourneyLocation>> resolveLocations({
    required String query,
    required List<RouteModel> routes,
    LatLng? userLocation,
    CancelToken? cancelToken,
  }) async {
    final cleanQ = query.trim().toLowerCase();
    final results = <JourneyLocation>[];
    final seenNames = <String>{};

    // Current location prompt
    if (cleanQ.isEmpty ||
        'current location'.contains(cleanQ) ||
        'my location'.contains(cleanQ)) {
      if (userLocation != null) {
        results.add(
          JourneyLocation(
            name: 'Current location',
            subtitle: 'Your detected GPS location',
            coordinate: userLocation,
            type: JourneyLocationType.currentLocation,
            isCurrentLocation: true,
          ),
        );
      }
    }

    if (cleanQ.isEmpty) {
      results.addAll(JourneyLocation.prominentPlaces);
      return results;
    }

    // 1. Local-first search: Prominent places & hubs
    for (final place in JourneyLocation.prominentPlaces) {
      final nameLower = place.name.toLowerCase();
      final subtitleLower = place.subtitle?.toLowerCase() ?? '';
      if (nameLower.contains(cleanQ) || subtitleLower.contains(cleanQ)) {
        if (!seenNames.contains(nameLower)) {
          seenNames.add(nameLower);
          results.add(place);
        }
      }
    }

    // 2. Local-first search: Verified GTFS stops across routes
    for (final route in routes) {
      for (final stop in route.stops) {
        final stopNameLower = stop.name.toLowerCase();
        if (stopNameLower.contains(cleanQ) && !seenNames.contains(stopNameLower)) {
          seenNames.add(stopNameLower);
          results.add(
            JourneyLocation(
              name: stop.name,
              subtitle: 'Verified Stop on Route ${route.shortName} (${route.name})',
              coordinate: stop.coordinates,
              type: JourneyLocationType.verifiedStop,
              stopId: stop.id,
              routeId: route.id,
            ),
          );
        }
      }
    }

    // 3. External geocoding resolution (if query >= 3 characters)
    if (cleanQ.length >= 3) {
      final externalPlaces = await _geocodingService.resolvePlace(
        query,
        cancelToken: cancelToken,
      );

      for (final place in externalPlaces) {
        final placeLower = place.name.toLowerCase();
        if (!seenNames.contains(placeLower)) {
          seenNames.add(placeLower);
          results.add(place);
        }
      }
    }

    return results;
  }

  /// Discovers and evaluates candidate transit access stops for an arbitrary
  /// destination coordinate.
  ///
  /// Evaluates:
  /// - Walking distance and walking minutes
  /// - Route connectivity and corridor significance
  /// - Suitability score (closer + major transit corridor = higher score)
  List<TransitAccessStop> findCandidateAccessStops({
    required LatLng destinationCoordinate,
    required List<RouteModel> routes,
    double maxRadiusMeters = defaultMaxWalkRadiusMeters,
  }) {
    final candidateStops = <TransitAccessStop>[];
    final seenStopKeys = <String>{};

    for (final route in routes) {
      for (final stop in route.stops) {
        final dist = calculateDistance(destinationCoordinate, stop.coordinates);
        if (dist <= maxRadiusMeters) {
          final key = '${route.id}_${stop.id}';
          if (!seenStopKeys.contains(key)) {
            seenStopKeys.add(key);

            final walkMins = math.max(1, (dist / _walkingSpeedMetersPerMinute).round());

            // Suitability score calculation:
            // Proximity base (up to 80 points)
            final proximityScore = math.max(0.0, 80.0 * (1.0 - (dist / maxRadiusMeters)));

            // Hub bonus (major terminals like Margao KTC / Panaji KTC / Vasco)
            final isHub = stop.name.toLowerCase().contains('bus stand') ||
                stop.name.toLowerCase().contains('ktc') ||
                stop.name.toLowerCase().contains('terminal');
            final hubBonus = isHub ? 15.0 : 0.0;

            final score = proximityScore + hubBonus;

            final explanation = dist < 200.0
                ? 'Direct access • ${dist.round()}m ($walkMins min walk)'
                : 'Connecting access • ${dist.round()}m ($walkMins min walk)';

            candidateStops.add(
              TransitAccessStop(
                stop: stop,
                route: route,
                walkingDistanceMeters: dist,
                walkingMinutes: walkMins,
                suitabilityScore: score,
                explanation: explanation,
              ),
            );
          }
        }
      }
    }

    // Sort by suitability score descending (best candidate first)
    candidateStops.sort();
    return candidateStops;
  }

  /// Finds the absolute closest transit stop in the network, regardless of radius.
  /// Used to provide actionable guidance when no stop is within walking radius.
  TransitAccessStop? findClosestStopOverall({
    required LatLng destinationCoordinate,
    required List<RouteModel> routes,
  }) {
    TransitAccessStop? closest;
    double minDistance = double.infinity;

    for (final route in routes) {
      for (final stop in route.stops) {
        final dist = calculateDistance(destinationCoordinate, stop.coordinates);
        if (dist < minDistance) {
          minDistance = dist;
          final walkMins = (dist / _walkingSpeedMetersPerMinute).round();
          closest = TransitAccessStop(
            stop: stop,
            route: route,
            walkingDistanceMeters: dist,
            walkingMinutes: walkMins,
            suitabilityScore: 0.0,
            explanation: 'Nearest network stop (${(dist / 1000.0).toStringAsFixed(1)} km away)',
          );
        }
      }
    }

    return closest;
  }
}
