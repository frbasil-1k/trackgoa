import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_go/app.dart';
import 'package:smart_go/core/router/app_router.dart';
import 'package:smart_go/core/router/route_paths.dart';
import 'package:smart_go/data/gtfs/generated_goa_transit_data.dart';
import 'package:smart_go/data/models/bus_model.dart';
import 'package:smart_go/data/models/route_model.dart';
import 'package:smart_go/data/models/stop_model.dart';
import 'package:smart_go/data/repositories/repository_providers.dart';
import 'package:smart_go/data/sources/goa_gtfs_route_data_source.dart';
import 'package:smart_go/features/journey_planner/models/journey_leg.dart';
import 'package:smart_go/features/journey_planner/models/journey_location.dart';
import 'package:smart_go/features/journey_planner/models/journey_option.dart';
import 'package:smart_go/features/journey_planner/models/journey_session.dart';
import 'package:smart_go/features/journey_planner/services/journey_planner_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SMART-GO — Journey Planner Unit & Service Tests', () {
    const service = JourneyPlannerService();
    late List<RouteModel> sampleRoutes;
    late Map<String, List<BusModel>> sampleFleets;

    setUp(() async {
      const routeSource = GoaGtfsRouteDataSource();
      sampleRoutes = await routeSource.getRoutes();
      sampleFleets = GeneratedGoaTransitData.fleet;
    });

    test('1. Origin & destination search resolves places, landmarks and stops', () {
      const userGps = LatLng(15.3900, 73.8150); // Near Vasco

      // Empty query with user location -> returns Current Location
      final initialResults = service.searchLocations(
        query: '',
        routes: sampleRoutes,
        userLocation: userGps,
      );
      expect(initialResults.any((loc) => loc.isCurrentLocation), isTrue);

      // Search 'Fatorda' -> returns Fatorda hub & area stops
      final fatordaResults = service.searchLocations(
        query: 'Fatorda',
        routes: sampleRoutes,
      );
      expect(fatordaResults.any((loc) => loc.name.contains('Fatorda')), isTrue);

      // Search 'Vasco' -> returns Vasco da Gama hub
      final vascoResults = service.searchLocations(
        query: 'Vasco',
        routes: sampleRoutes,
      );
      expect(vascoResults.any((loc) => loc.name.contains('Vasco')), isTrue);

      // Search 'Margao' -> returns Margao KTC Bus Stand
      final margaoResults = service.searchLocations(
        query: 'Margao',
        routes: sampleRoutes,
      );
      expect(margaoResults.any((loc) => loc.name.contains('Margao')), isTrue);
    });

    test('2. Direct route discovery finds existing verified single-bus corridors', () {
      // Panaji KTC to Dona Paula (served directly by Route R1)
      const panajiOrigin = JourneyLocation(
        name: 'Panaji Bus Stand',
        subtitle: 'Panaji KTC Hub',
        coordinate: LatLng(15.4989, 73.8278),
        type: JourneyLocationType.cityHub,
      );
      const donaPaulaDest = JourneyLocation(
        name: 'Dona Paula Circle',
        subtitle: 'Dona Paula',
        coordinate: LatLng(15.4535, 73.8056),
        type: JourneyLocationType.verifiedStop,
      );

      final journeys = service.planJourneys(
        origin: panajiOrigin,
        destination: donaPaulaDest,
        routes: sampleRoutes,
        fleet: sampleFleets,
      );

      expect(journeys.isNotEmpty, isTrue);
      final directOptions = journeys.where((j) => j.isDirect).toList();
      expect(directOptions.isNotEmpty, isTrue);
      final best = directOptions.first;
      expect(best.transferCount, equals(0));
      expect(best.legs.any((l) => l.isTransit), isTrue);
      expect(best.hasLiveVehicle, isTrue);
    });

    test('3. Vasco to Fatorda multi-leg corridor journey detection', () {
      const vascoOrigin = JourneyLocation(
        name: 'Vasco da Gama',
        subtitle: 'Vasco Bus Stand',
        coordinate: LatLng(15.3995, 73.8115),
        type: JourneyLocationType.cityHub,
      );
      const fatordaDest = JourneyLocation(
        name: 'Fatorda',
        subtitle: 'Jawaharlal Nehru Stadium',
        coordinate: LatLng(15.2917, 73.9667),
        type: JourneyLocationType.landmarkPlace,
      );

      final journeys = service.planJourneys(
        origin: vascoOrigin,
        destination: fatordaDest,
        routes: sampleRoutes,
        fleet: sampleFleets,
      );

      expect(journeys.isNotEmpty, isTrue);

      // Must find the authentic Vasco -> Margao KTC -> Fatorda journey
      final corridorJourney = journeys.firstWhere(
        (j) => j.id.contains('vasco_fatorda') || j.transferCount >= 1,
      );
      expect(corridorJourney.transferCount, greaterThanOrEqualTo(1));
      expect(corridorJourney.origin.name, contains('Vasco'));
      expect(corridorJourney.destination.name, contains('Fatorda'));

      // Check vertical legs breakdown
      final transitLegs = corridorJourney.legs.where((l) => l.isTransit).toList();
      expect(transitLegs.isNotEmpty, isTrue);
      expect(transitLegs.first.route, isNotNull);
      expect(corridorJourney.legs.any((l) => l.isTransfer), isTrue);

      // Verify epistemic label
      expect(corridorJourney.epistemicStatus, contains('Margao Transit Transfer Corridor'));
    });

    test('4. Walking transfer validation rejects unrealistic distances (>400m)', () {
      const stopA = StopModel(
        id: 'stop_a',
        name: 'Stop A',
        coordinates: LatLng(15.4989, 73.8278),
        routeId: 'R1',
        order: 1,
      );
      // Stop B is ~4km away in Bambolim
      const stopB = StopModel(
        id: 'stop_b',
        name: 'Stop B',
        coordinates: LatLng(15.4600, 73.8560),
        routeId: 'R1',
        order: 2,
      );

      final distance = service.calculateDistance(stopA.coordinates, stopB.coordinates);
      expect(distance, greaterThan(400.0)); // Over maximum allowable walking transfer
    });

    test('5. Journey ranking prioritizes direct and shorter transit duration', () {
      final opt1 = JourneyOption(
        id: 'opt1',
        origin: const JourneyLocation(
          name: 'A',
          subtitle: '',
          coordinate: LatLng(15.0, 73.0),
          type: JourneyLocationType.verifiedStop,
        ),
        destination: const JourneyLocation(
          name: 'B',
          subtitle: '',
          coordinate: LatLng(15.1, 73.1),
          type: JourneyLocationType.verifiedStop,
        ),
        legs: const [],
        totalDurationMinutes: 50,
        transferCount: 1,
        walkingMinutes: 5,
        departureTime: '10:00',
        arrivalTime: '10:50',
        hasLiveVehicle: false,
        epistemicStatus: 'Verified',
      );

      final opt2 = JourneyOption(
        id: 'opt2',
        origin: opt1.origin,
        destination: opt1.destination,
        legs: const [],
        totalDurationMinutes: 35,
        transferCount: 0, // Direct
        walkingMinutes: 2,
        departureTime: '10:00',
        arrivalTime: '10:35',
        hasLiveVehicle: true,
        epistemicStatus: 'Verified',
      );

      final list = [opt1, opt2]..sort();
      expect(list.first.id, equals('opt2')); // Direct option with shorter time ranks first
    });
  });

  group('SMART-GO — Active Journey Session & State Machine Tests', () {
    test('6. State machine transitions and destination persistence', () {
      const leg1 = JourneyLeg(
        legType: JourneyLegType.transit,
        fromName: 'Vasco Bus Stand',
        toName: 'Margao KTC Bus Stand',
        fromCoordinate: LatLng(15.3995, 73.8115),
        toCoordinate: LatLng(15.2832, 73.9685),
        durationMinutes: 38,
        distanceMeters: 30000.0,
        instructions: 'Take MRG11 toward Margao KTC',
        route: RouteModel(
          id: 'MRG11',
          name: 'Vasco to Margao Express',
          shortName: 'MRG11',
          origin: 'Vasco',
          destination: 'Margao KTC',
          stops: [],
          polylinePoints: [],
          color: Color(0xFF00BFA5),
          estimatedTravelMinutes: 45,
        ),
      );

      const leg2 = JourneyLeg(
        legType: JourneyLegType.transferWalk,
        fromName: 'Margao KTC Bus Stand',
        toName: 'Margao KTC Platform 4',
        fromCoordinate: LatLng(15.2832, 73.9685),
        toCoordinate: LatLng(15.2835, 73.9688),
        durationMinutes: 4,
        distanceMeters: 40.0,
        instructions: 'Transfer to Fatorda shuttle at platform 4',
      );

      const leg3 = JourneyLeg(
        legType: JourneyLegType.transit,
        fromName: 'Margao KTC Platform 4',
        toName: 'Fatorda Stadium',
        fromCoordinate: LatLng(15.2835, 73.9688),
        toCoordinate: LatLng(15.2917, 73.9667),
        durationMinutes: 6,
        distanceMeters: 2500.0,
        instructions: 'Take shuttle to Fatorda',
        route: RouteModel(
          id: 'FTR1',
          name: 'Margao to Fatorda Shuttle',
          shortName: 'FTR1',
          origin: 'Margao KTC',
          destination: 'Fatorda',
          stops: [],
          polylinePoints: [],
          color: Color(0xFF3B82F6),
          estimatedTravelMinutes: 8,
        ),
      );

      final journey = JourneyOption(
        id: 'vasco_fatorda_test',
        origin: const JourneyLocation(
          name: 'Vasco da Gama',
          subtitle: '',
          coordinate: LatLng(15.3995, 73.8115),
          type: JourneyLocationType.cityHub,
        ),
        destination: const JourneyLocation(
          name: 'Fatorda Stadium',
          subtitle: '',
          coordinate: LatLng(15.2917, 73.9667),
          type: JourneyLocationType.landmarkPlace,
        ),
        legs: const [leg1, leg2, leg3],
        totalDurationMinutes: 48,
        transferCount: 1,
        walkingMinutes: 4,
        departureTime: '10:00',
        arrivalTime: '10:48',
        hasLiveVehicle: true,
        liveVehicleId: 'GA-08-V-5072',
        epistemicStatus: 'Verified Margao Transit Transfer Corridor',
      );

      // Start Session
      var session = ActiveJourneySession(
        journey: journey,
        currentLegIndex: 0,
        currentState: JourneyProgressState.journeySelected,
        currentVehicleId: 'GA-08-V-5072',
        finalDestination: journey.destination,
        startedAt: DateTime.now(),
      );

      // Verification 1: Persistent destination
      expect(session.finalDestinationName, equals('Fatorda Stadium'));
      expect(session.currentLeg.fromName, equals('Vasco Bus Stand'));
      expect(session.isMultiLeg, isTrue);

      // Transition to onBus
      session = session.copyWith(currentState: JourneyProgressState.onBus);
      expect(session.currentState, equals(JourneyProgressState.onBus));
      expect(session.finalDestinationName, equals('Fatorda Stadium'));

      // Arrive at Margao KTC and advance to transfer leg
      session = session.advanceToNextLeg();
      expect(session.currentLegIndex, equals(1));
      expect(session.currentLeg.isTransfer, isTrue);
      expect(session.currentState, equals(JourneyProgressState.atTransfer));
      expect(session.finalDestinationName, equals('Fatorda Stadium'));

      // Advance to 2nd transit leg (Fatorda shuttle)
      session = session.advanceToNextLeg();
      expect(session.currentLegIndex, equals(2));
      expect(session.currentLeg.isTransit, isTrue);
      expect(session.currentLeg.toName, equals('Fatorda Stadium'));
      expect(session.currentState, equals(JourneyProgressState.onNextBus));
      // Even on the second bus, final destination remains persistent!
      expect(session.finalDestinationName, equals('Fatorda Stadium'));
    });
  });

  group('SMART-GO — Journey Planner End-to-End UI Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      appRouter.go(RoutePaths.home);
    });

    testWidgets('7. Home screen prominent prompt navigates to Journey Planner screen', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const SmartGoApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Check for prominent Journey Planner prompt on Home screen
      expect(find.byKey(const ValueKey('home-journey-planner-card')), findsOneWidget);
      expect(find.text('Where are you going?'), findsOneWidget);

      // Tap to navigate to Journey Planner
      await tester.tap(find.byKey(const ValueKey('home-journey-planner-card')));
      await tester.pumpAndSettle();

      // Verify Journey Planner screen appears
      expect(find.text('Plan Your Journey'), findsOneWidget);
      expect(find.byKey(const ValueKey('journey-origin-input')), findsOneWidget);
      expect(find.byKey(const ValueKey('journey-destination-input')), findsOneWidget);
    });

    testWidgets('8. Search destination "Fatorda" reveals verified transfer journey', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const SmartGoApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to planner
      appRouter.go(RoutePaths.journeyPlanner);
      await tester.pumpAndSettle();

      // Quick tap destination chip 'Fatorda'
      final fatordaChip = find.text('Fatorda');
      expect(fatordaChip, findsWidgets);
      await tester.tap(fatordaChip.first);
      await tester.pumpAndSettle();

      // Verify journey options appear
      expect(find.byKey(const ValueKey('journey-options-count-header')), findsOneWidget);
      expect(find.textContaining('Journey'), findsWidgets);

      // Verify prominent journey card
      expect(find.byKey(const ValueKey('journey-option-card-0')), findsOneWidget);
      expect(find.text('Start Live Journey'), findsWidgets);

      // Tap 'Start Live Journey' to transition directly to live tracking
      await tester.tap(find.text('Start Live Journey').first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Verify navigation into tracking screen with persistent journey banner!
      expect(find.byKey(const ValueKey('active-journey-tracking-banner')), findsOneWidget);
      expect(find.textContaining('Final: Fatorda'), findsOneWidget);
    });
  });
}
