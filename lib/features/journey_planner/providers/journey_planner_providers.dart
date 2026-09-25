import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/gtfs/generated_goa_transit_data.dart';
import '../../home/providers/home_providers.dart';
import '../models/journey_location.dart';
import '../models/journey_option.dart';
import '../models/journey_session.dart';
import '../models/transit_access_stop.dart';
import '../services/destination_resolver_service.dart';
import '../services/geocoding_service.dart';
import '../services/journey_planner_service.dart';

/// Provides singleton instance of the JourneyPlannerService.
final journeyPlannerServiceProvider = Provider<JourneyPlannerService>((ref) {
  return const JourneyPlannerService();
});

/// Provides singleton instance of the GeocodingService.
final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  return GeocodingService();
});

/// Provides singleton instance of DestinationResolverService with geocoding integration.
final destinationResolverServiceProvider = Provider<DestinationResolverService>((ref) {
  final geocoding = ref.watch(geocodingServiceProvider);
  return DestinationResolverService(geocodingService: geocoding);
});

/// Safely detects the passenger's current GPS location if permissions are granted.
/// Falls back gracefully to default Panaji KTC if permission is denied or service unavailable.
final detectedCurrentLocationProvider = FutureProvider<JourneyLocation>((ref) async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return JourneyLocation.fallbackOrigin;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return JourneyLocation.fallbackOrigin;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return JourneyLocation.fallbackOrigin;
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 4),
      ),
    );

    return JourneyLocation(
      name: 'Current location',
      subtitle: 'GPS detected position in Goa',
      coordinate: LatLng(pos.latitude, pos.longitude),
      type: JourneyLocationType.currentLocation,
      isCurrentLocation: true,
      isApproximate: false,
    );
  } catch (_) {
    return JourneyLocation.fallbackOrigin;
  }
});

/// The passenger's selected journey origin.
final journeyOriginProvider = StateProvider<JourneyLocation>((ref) {
  final detected = ref.watch(detectedCurrentLocationProvider).value;
  return detected ?? JourneyLocation.fallbackOrigin;
});

/// The passenger's selected journey destination.
final journeyDestinationProvider = StateProvider<JourneyLocation?>((ref) {
  return null;
});

/// Quick search query for destination or origin search.
final journeySearchQueryProvider = StateProvider<String>((ref) => '');

/// Computed search results for places, hubs, verified stops, and geocoded locations.
final journeySearchResultsProvider =
    FutureProvider.autoDispose<List<JourneyLocation>>((ref) async {
  final query = ref.watch(journeySearchQueryProvider);
  final resolver = ref.watch(destinationResolverServiceProvider);
  final routes = ref.watch(homeRoutesProvider).value ?? GeneratedGoaTransitData.routes;
  final userLocation = ref.watch(journeyOriginProvider).coordinate;

  return resolver.resolveLocations(
    query: query,
    routes: routes,
    userLocation: userLocation,
  );
});

/// Finds the nearest available transit stop in the network when no journey connects
/// to the destination within reasonable walking distance.
final nearestTransitStopProvider = Provider<TransitAccessStop?>((ref) {
  final destination = ref.watch(journeyDestinationProvider);
  if (destination == null) return null;
  final resolver = ref.watch(destinationResolverServiceProvider);
  final routes = ref.watch(homeRoutesProvider).value ?? GeneratedGoaTransitData.routes;
  return resolver.findClosestStopOverall(
    destinationCoordinate: destination.coordinate,
    routes: routes,
  );
});

/// Computed journey options matching current origin & destination.
final journeyOptionsProvider = Provider<List<JourneyOption>>((ref) {
  final origin = ref.watch(journeyOriginProvider);
  final destination = ref.watch(journeyDestinationProvider);
  if (destination == null) return const [];

  final service = ref.watch(journeyPlannerServiceProvider);
  final routes = ref.watch(homeRoutesProvider).value ?? GeneratedGoaTransitData.routes;
  final fleet = GeneratedGoaTransitData.fleet;

  return service.findJourneys(
    origin: origin,
    destination: destination,
    routes: routes,
    fleet: fleet,
  );
});

/// Currently selected journey option for preview and execution.
final selectedJourneyOptionProvider = StateProvider<JourneyOption?>((ref) {
  final options = ref.watch(journeyOptionsProvider);
  return options.isNotEmpty ? options.first : null;
});

/// StateNotifier that manages active journey execution, leg transitions, and tracking sync.
class ActiveJourneySessionNotifier extends StateNotifier<ActiveJourneySession?> {
  ActiveJourneySessionNotifier() : super(null);

  void startJourney(JourneyOption journey) {
    final firstTransit = journey.firstTransitLeg;
    state = ActiveJourneySession(
      journey: journey,
      currentLegIndex: 0,
      currentState: JourneyProgressState.journeySelected,
      currentVehicleId: firstTransit?.recommendedVehicle?.id,
      finalDestination: journey.destination,
      startedAt: DateTime.now(),
    );
  }

  void advanceToNextLeg() {
    if (state == null) return;
    if (state!.hasNextLeg) {
      final nextIdx = state!.currentLegIndex + 1;
      final nextLeg = state!.journey.legs[nextIdx];
      state = state!.copyWith(
        currentLegIndex: nextIdx,
        currentVehicleId: nextLeg.recommendedVehicle?.id ?? state!.currentVehicleId,
        currentState: nextLeg.isTransit
            ? JourneyProgressState.onBus
            : JourneyProgressState.walkingToFirstStop,
      );
    } else {
      state = state!.copyWith(
        currentState: JourneyProgressState.arrived,
      );
    }
  }

  void updateState(JourneyProgressState newState) {
    if (state == null) return;
    state = state!.copyWith(currentState: newState);
  }

  void cancelJourney() {
    state = null;
  }
}

/// Active execution context across SMART-GO (home, planner, and tracking screens).
final activeJourneySessionProvider =
    StateNotifierProvider<ActiveJourneySessionNotifier, ActiveJourneySession?>((ref) {
  return ActiveJourneySessionNotifier();
});
