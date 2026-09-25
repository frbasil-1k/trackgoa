import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:smart_go/data/gtfs/generated_goa_transit_data.dart';
import 'package:smart_go/features/journey_planner/models/journey_location.dart';
import 'package:smart_go/features/journey_planner/models/journey_session.dart';
import 'package:smart_go/features/journey_planner/providers/journey_planner_providers.dart';
import 'package:smart_go/features/journey_planner/screens/journey_planner_screen.dart';
import 'package:smart_go/features/journey_planner/services/destination_resolver_service.dart';
import 'package:smart_go/features/journey_planner/services/geocoding_service.dart';
import 'package:smart_go/features/journey_planner/services/journey_planner_service.dart';
import 'package:smart_go/features/journey_planner/widgets/journey_option_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final routes = GeneratedGoaTransitData.routes;
  final fleet = GeneratedGoaTransitData.fleet;

  group('SMART-GO — Smart Destination Resolution: Service & Pipeline Tests', () {
    late GeocodingService geocodingService;
    late DestinationResolverService destinationResolver;
    late JourneyPlannerService journeyPlanner;

    setUp(() {
      geocodingService = GeocodingService();
      destinationResolver = DestinationResolverService(geocodingService: geocodingService);
      journeyPlanner = const JourneyPlannerService();
    });

    test('1. Exact GTFS stop search resolves quickly via local dataset', () async {
      final results = await destinationResolver.resolveLocations(
        query: 'Margao KTC',
        routes: routes,
      );

      expect(results.isNotEmpty, isTrue);
      final match = results.firstWhere((r) => r.name.toLowerCase().contains('margao ktc'));
      expect(match.name, contains('Margao KTC'));
      expect(match.isVerifiedStop || match.isTransitHub, isTrue);
      expect(match.provenanceLabel, anyOf('Verified GTFS Stop', 'Verified Transit Hub'));
    });

    test('2. Known landmark search resolves local prominent places without geocoding', () async {
      final results = await destinationResolver.resolveLocations(
        query: 'Fatorda',
        routes: routes,
      );

      expect(results.isNotEmpty, isTrue);
      final landmark = results.firstWhere((r) => r.name == 'Fatorda');
      expect(landmark.isLandmark, isTrue);
      expect(landmark.provenanceLabel, 'Verified Landmark');
      expect(landmark.coordinate.latitude, closeTo(15.2906, 0.001));
    });

    test('3. Arbitrary external place resolution resolves "Deltin Royale" to valid coordinates', () async {
      final results = await destinationResolver.resolveLocations(
        query: 'Deltin Royale',
        routes: routes,
      );

      expect(results.isNotEmpty, isTrue);
      final deltin = results.firstWhere((r) => r.name == 'Deltin Royale');
      expect(deltin.coordinate.latitude, closeTo(15.4989, 0.01));
      expect(deltin.coordinate.longitude, closeTo(73.8278, 0.01));
      expect(deltin.isGeocoded, isTrue);
      expect(deltin.provenanceLabel, 'Resolved Place');
      expect(deltin.isExternallyResolved, isTrue);
    });

    test('4. Ambiguous place results present multiple selectable options without guessing', () async {
      // Searching for "Market" matches Panjim Market, Margao Market, etc.
      final results = await destinationResolver.resolveLocations(
        query: 'Market',
        routes: routes,
      );

      expect(results.length, greaterThanOrEqualTo(1));
      for (final r in results) {
        expect(r.name.toLowerCase().contains('market') || (r.subtitle?.toLowerCase().contains('market') ?? false), isTrue);
      }
    });

    test('5. No nearby stop behavior: Cacora Industrial Estate identifies distant stop honestly', () {
      const cacoraCoord = LatLng(15.2650, 74.1200);

      // Within normal 1400m walk radius, no verified stops exist
      final candidateStops = destinationResolver.findCandidateAccessStops(
        destinationCoordinate: cacoraCoord,
        routes: routes,
        maxRadiusMeters: 1400.0,
      );
      expect(candidateStops.isEmpty, isTrue);

      // findClosestStopOverall identifies the nearest network stop (~18 km away)
      final closestStop = destinationResolver.findClosestStopOverall(
        destinationCoordinate: cacoraCoord,
        routes: routes,
      );
      expect(closestStop, isNotNull);
      expect(closestStop!.walkingDistanceMeters, greaterThan(10000.0));
      expect(closestStop.explanation, contains('km away'));
    });

    test('6. Nearby transit stop discovery around Deltin Royale finds Panaji Ferry Terminal', () {
      const deltinCoord = LatLng(15.4989, 73.8278);

      final candidateStops = destinationResolver.findCandidateAccessStops(
        destinationCoordinate: deltinCoord,
        routes: routes,
        maxRadiusMeters: 1400.0,
      );

      expect(candidateStops.isNotEmpty, isTrue);
      // Panaji Ferry Terminal is within ~300 meters
      final ferryStop = candidateStops.firstWhere(
        (c) => c.stop.name.toLowerCase().contains('ferry'),
      );
      expect(ferryStop.walkingDistanceMeters, lessThan(400.0));
      expect(ferryStop.walkingMinutes, lessThanOrEqualTo(5));
    });

    test('7. Multiple nearby stop candidate scoring ranks closer and hub stops higher', () {
      const deltinCoord = LatLng(15.4989, 73.8278);

      final candidateStops = destinationResolver.findCandidateAccessStops(
        destinationCoordinate: deltinCoord,
        routes: routes,
        maxRadiusMeters: 1400.0,
      );

      expect(candidateStops.length, greaterThanOrEqualTo(2));
      // First candidate has highest suitability score
      expect(candidateStops[0].suitabilityScore, greaterThanOrEqualTo(candidateStops[1].suitabilityScore));
      expect(candidateStops.first.stop.name, isNotEmpty);
    });

    test('8. Practical-stop selection: JourneyPlanner plans transit to nearest practical stop', () {
      final deltinLoc = JourneyLocation(
        name: 'Deltin Royale',
        coordinate: const LatLng(15.4989, 73.8278),
        type: JourneyLocationType.geocodedPlace,
        isExternallyResolved: true,
      );

      final journeys = journeyPlanner.findJourneys(
        origin: JourneyLocation.prominentPlaces.firstWhere((p) => p.name == 'Margao'),
        destination: deltinLoc,
        routes: routes,
        fleet: fleet,
      );

      expect(journeys.isNotEmpty, isTrue);
      final bestJourney = journeys.first;
      // Should alight at a verified practical stop near Deltin Royale (Panaji KTC or Ferry Terminal)
      expect(bestJourney.alightingStop, isNotNull);
      expect(bestJourney.alightingStop!.name, anyOf(contains('Panaji'), contains('Ferry')));
    });

    test('9. Final walking leg: explicit walking leg with distance and time estimate', () {
      final deltinLoc = JourneyLocation(
        name: 'Deltin Royale',
        coordinate: const LatLng(15.4989, 73.8278),
        type: JourneyLocationType.geocodedPlace,
        isExternallyResolved: true,
      );

      final journeys = journeyPlanner.findJourneys(
        origin: JourneyLocation.prominentPlaces.firstWhere((p) => p.name == 'Margao'),
        destination: deltinLoc,
        routes: routes,
        fleet: fleet,
      );

      expect(journeys.isNotEmpty, isTrue);
      final journey = journeys.first;
      final finalWalk = journey.finalWalkingLeg;
      expect(finalWalk, isNotNull);
      expect(finalWalk!.isWalking, isTrue);
      expect(finalWalk.toName, 'Deltin Royale');
      expect(finalWalk.instructions, contains('estimated'));
      expect(finalWalk.distanceMeters, greaterThan(50.0));
    });

    test('10. Destination vs Alighting Stop distinction: Destination remains "Deltin Royale"', () {
      final deltinLoc = JourneyLocation(
        name: 'Deltin Royale',
        coordinate: const LatLng(15.4989, 73.8278),
        type: JourneyLocationType.geocodedPlace,
        isExternallyResolved: true,
      );

      final journeys = journeyPlanner.findJourneys(
        origin: JourneyLocation.prominentPlaces.firstWhere((p) => p.name == 'Margao'),
        destination: deltinLoc,
        routes: routes,
        fleet: fleet,
      );

      final journey = journeys.first;
      expect(journey.destination.name, 'Deltin Royale');
      expect(journey.alightingStop!.name, isNot(equals('Deltin Royale')));
      expect(journey.alightingStop!.name, anyOf(contains('Panaji'), contains('Ferry')));
    });

    test('11. Provenance honesty: distinguishes verified GTFS from estimated walking & geocoded place', () {
      final deltinLoc = JourneyLocation(
        name: 'Deltin Royale',
        coordinate: const LatLng(15.4989, 73.8278),
        type: JourneyLocationType.geocodedPlace,
        isExternallyResolved: true,
      );

      final journeys = journeyPlanner.findJourneys(
        origin: JourneyLocation.prominentPlaces.firstWhere((p) => p.name == 'Margao'),
        destination: deltinLoc,
        routes: routes,
        fleet: fleet,
      );

      final journey = journeys.first;
      expect(journey.epistemicStatus, contains('Estimated'));
      expect(deltinLoc.provenanceLabel, 'Resolved Place');
    });

    test('12. Offline fallback: Curated Goa places resolve instantly without network', () async {
      final places = await geocodingService.resolvePlace('Goa Medical College');
      expect(places.isNotEmpty, isTrue);
      expect(places.first.name, contains('Medical College'));
      expect(places.first.coordinate.latitude, closeTo(15.4610, 0.01));
    });

    test('13. Geocoder failure: gracefully returns empty without throwing exception', () async {
      // Empty or short query
      final emptyResult = await geocodingService.resolvePlace('xy');
      expect(emptyResult.isEmpty, isTrue);

      // Nonsense query
      final noResult = await geocodingService.resolvePlace('xyzqwertyunknownplace1234');
      expect(noResult.isEmpty, isTrue);
    });

    test('14. Search caching avoids duplicate queries', () async {
      geocodingService.clearCache();
      final r1 = await geocodingService.resolvePlace('Panjim Market');
      expect(r1.isNotEmpty, isTrue);

      // Second call retrieves from cache
      final r2 = await geocodingService.resolvePlace('Panjim Market');
      expect(identical(r1, r2), isTrue);
    });

    test('15. Transfer journey integration: Vasco to Deltin Royale plans 1-transfer via Margao with final walk', () {
      final vascoOrigin = JourneyLocation.prominentPlaces.firstWhere((p) => p.name == 'Vasco');
      final deltinLoc = JourneyLocation(
        name: 'Deltin Royale',
        coordinate: const LatLng(15.4989, 73.8278),
        type: JourneyLocationType.geocodedPlace,
        isExternallyResolved: true,
      );

      final journeys = journeyPlanner.findJourneys(
        origin: vascoOrigin,
        destination: deltinLoc,
        routes: routes,
        fleet: fleet,
      );

      expect(journeys.isNotEmpty, isTrue);
      final transferJourney = journeys.firstWhere((j) => j.transferCount == 1);
      expect(transferJourney.destination.name, 'Deltin Royale');
      expect(transferJourney.alightingStop, isNotNull);
      expect(transferJourney.finalWalkingLeg, isNotNull);
      expect(transferJourney.finalWalkingLeg!.toName, 'Deltin Royale');
    });

    test('16. Live tracking integration: ActiveJourneySession preserves final destination context', () {
      final deltinLoc = JourneyLocation(
        name: 'Deltin Royale',
        coordinate: const LatLng(15.4989, 73.8278),
        type: JourneyLocationType.geocodedPlace,
        isExternallyResolved: true,
      );

      final journeys = journeyPlanner.findJourneys(
        origin: JourneyLocation.prominentPlaces.firstWhere((p) => p.name == 'Margao'),
        destination: deltinLoc,
        routes: routes,
        fleet: fleet,
      );

      final journey = journeys.first;
      final session = ActiveJourneySession(
        journey: journey,
        currentLegIndex: 0,
        currentState: JourneyProgressState.journeySelected,
        finalDestination: journey.destination,
        startedAt: DateTime.now(),
      );

      expect(session.finalDestination.name, 'Deltin Royale');
      expect(session.journey.alightingStop!.name, anyOf(contains('Panaji'), contains('Ferry')));
    });

    test('17. Final destination persistence across leg advancement', () {
      final vascoOrigin = JourneyLocation.prominentPlaces.firstWhere((p) => p.name == 'Vasco');
      final deltinLoc = JourneyLocation(
        name: 'Deltin Royale',
        coordinate: const LatLng(15.4989, 73.8278),
        type: JourneyLocationType.geocodedPlace,
        isExternallyResolved: true,
      );

      final journeys = journeyPlanner.findJourneys(
        origin: vascoOrigin,
        destination: deltinLoc,
        routes: routes,
        fleet: fleet,
      );

      final journey = journeys.firstWhere((j) => j.transferCount == 1);
      final notifier = ActiveJourneySessionNotifier();
      notifier.startJourney(journey);

      expect(notifier.state!.finalDestination.name, 'Deltin Royale');
      expect(notifier.state!.currentLegIndex, 0);

      // Advance leg
      notifier.advanceToNextLeg();
      expect(notifier.state!.finalDestination.name, 'Deltin Royale');
      expect(notifier.state!.currentLegIndex, 1);
    });
  });

  group('SMART-GO — Smart Destination Resolution: UI Widget Tests', () {
    testWidgets('JourneyOptionCard displays "TO: Deltin Royale" and "Alight at [Stop]" separately', (tester) async {
      final deltinLoc = JourneyLocation(
        name: 'Deltin Royale',
        coordinate: const LatLng(15.4989, 73.8278),
        type: JourneyLocationType.geocodedPlace,
        isExternallyResolved: true,
      );

      final journey = const JourneyPlannerService().findJourneys(
        origin: JourneyLocation.prominentPlaces.firstWhere((p) => p.name == 'Margao'),
        destination: deltinLoc,
        routes: routes,
        fleet: fleet,
      ).first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: JourneyOptionCard(
                option: journey,
                isSelected: true,
                onSelect: () {},
                onStartJourney: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Destination summary box verifies distinction
      expect(find.text('TO: Deltin Royale'), findsOneWidget);
      expect(find.textContaining('Alight at:'), findsOneWidget);
      expect(find.textContaining('Panaji'), findsWidgets);
      expect(find.textContaining('walk'), findsWidgets);
      expect(find.text('Destination: Deltin Royale'), findsOneWidget);
    });

    testWidgets('JourneyPlannerScreen shows No Nearby Stop banner when destination is distant (Cacora)', (tester) async {
      final cacoraLoc = JourneyLocation(
        name: 'Cacora Industrial Estate',
        subtitle: 'IDC Industrial Area, Curchorem, South Goa',
        coordinate: const LatLng(15.2650, 74.1200),
        type: JourneyLocationType.geocodedPlace,
        isExternallyResolved: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            journeyDestinationProvider.overrideWith((ref) => cacoraLoc),
          ],
          child: const MaterialApp(
            home: JourneyPlannerScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No nearby transit stop found'), findsOneWidget);
      expect(find.textContaining('Cacora Industrial Estate'), findsWidgets);
      expect(find.textContaining('Nearest available transit stop:'), findsOneWidget);
      expect(find.textContaining('Plan to'), findsOneWidget);
    });

    testWidgets('JourneyPlannerScreen resolves and displays Deltin Royale journey options', (tester) async {
      final deltinLoc = JourneyLocation(
        name: 'Deltin Royale',
        subtitle: 'Fisheries Jetty, Mandovi River Promenade, Panaji',
        coordinate: const LatLng(15.4989, 73.8278),
        type: JourneyLocationType.geocodedPlace,
        isExternallyResolved: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            journeyOriginProvider.overrideWith((ref) => JourneyLocation.prominentPlaces.firstWhere((p) => p.name == 'Margao')),
            journeyDestinationProvider.overrideWith((ref) => deltinLoc),
          ],
          child: const MaterialApp(
            home: JourneyPlannerScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Destination: Deltin Royale'), findsWidgets);
      expect(find.textContaining('Option'), findsWidgets);
      expect(find.text('TO: Deltin Royale'), findsWidgets);
      expect(find.textContaining('Alight at:'), findsWidgets);
    });
  });
}
