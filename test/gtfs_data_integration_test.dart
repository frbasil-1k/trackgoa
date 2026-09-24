import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_go/data/gtfs/generated_goa_transit_data.dart';
import 'package:smart_go/data/models/provenance_model.dart';
import 'package:smart_go/data/repositories/repository_providers.dart';
import 'package:smart_go/data/sources/goa_gtfs_route_data_source.dart';
import 'package:smart_go/features/routes/providers/route_list_providers.dart';

void main() {
  group('Batch 4 — Official Goa GTFS Transit Data Ingestion & Integration', () {
    test('GoaGtfsRouteDataSource loads authentic Goa transit routes with GTFS IDs',
        () async {
      const source = GoaGtfsRouteDataSource();
      final routes = await source.getRoutes();

      expect(routes.length, 6);

      // Key route identifiers (verbatim from GTFS routes.txt)
      final routeIds = routes.map((r) => r.id).toSet();
      expect(routeIds.contains('R1'), isTrue);
      expect(routeIds.contains('B1'), isTrue);
      expect(routeIds.contains('V1'), isTrue);
      expect(routeIds.contains('PNJ7'), isTrue);
      expect(routeIds.contains('MRG1'), isTrue);
      expect(routeIds.contains('MRG11'), isTrue);

      // Verify route short codes
      final shortNames = routes.map((r) => r.shortName).toSet();
      expect(shortNames.contains('R1'), isTrue);
      expect(shortNames.contains('B1'), isTrue);
      expect(shortNames.contains('V1'), isTrue);
      expect(shortNames.contains('PNJ7'), isTrue);
      expect(shortNames.contains('MRG1'), isTrue);
      expect(shortNames.contains('MRG11'), isTrue);
    });

    test('Stops contain authentic Goa landmarks and valid coordinates',
        () async {
      const source = GoaGtfsRouteDataSource();
      final r1 = await source.getRouteById('R1');

      expect(r1, isNotNull);
      expect(r1!.stops.length, 44);

      final stopNames = r1.stops.map((s) => s.name).toList();

      // Check authentic landmark stops on R1 (Panaji - Dona Paula circular corridor)
      expect(stopNames.contains('Panaji Bus Stand'), isTrue);
      expect(stopNames.contains('Old Secretariat A'), isTrue);
      expect(stopNames.contains('Panaji Ferry Terminal A'), isTrue);
      expect(stopNames.contains('Panjim Promenade A'), isTrue);
      expect(stopNames.contains('Kala Academy A'), isTrue);
      expect(stopNames.contains('Dona Paula Circle'), isTrue);
      expect(stopNames.contains('Miramar Beach Circle B'), isTrue);
      expect(stopNames.contains('Divja Circle'), isTrue);

      // Verify stop coordinate bounds (Goa latitude ~15.4 to 15.5, longitude ~73.8 to 73.85)
      for (final stop in r1.stops) {
        expect(stop.coordinates.latitude, inInclusiveRange(15.4, 15.6));
        expect(stop.coordinates.longitude, inInclusiveRange(73.7, 74.0));
      }
    });

    test('Route geometry is populated with road-snapped coordinates', () async {
      const source = GoaGtfsRouteDataSource();
      final routes = await source.getRoutes();

      for (final route in routes) {
        // Road-snapped geometry must contain smooth road points
        expect(route.polylinePoints.length, greaterThanOrEqualTo(100),
            reason: 'Route ${route.shortName} should have road-snapped polyline');

        // Points should be within Goa bounds
        for (final pt in route.polylinePoints) {
          expect(pt.latitude, inInclusiveRange(14.9, 15.9));
          expect(pt.longitude, inInclusiveRange(73.5, 74.3));
        }
      }
    });

    test('Official GTFS license and agency metadata is preserved', () {
      expect(GeneratedGoaTransitData.metadata['agency'],
          'Kadamba Transport Corporation Limited (KTCL)');
      expect(GeneratedGoaTransitData.metadata['publisher'],
          'Department of Transport, Government of Goa');
      expect(GeneratedGoaTransitData.metadata['license'],
          contains('Creative Commons Attribution 4.0'));
      expect(GeneratedGoaTransitData.metadata['publisherUrl'],
          'https://goatransport.gov.in/GTFS');
    });

    test('Provenance model records confidence levels across entities', () {
      final records = GeneratedGoaTransitData.provenance;
      expect(records, isNotEmpty);

      // Must have authoritative GTFS records (Confidence A)
      final authRecords = records.where((r) => r.confidence == ProvenanceConfidence.aAuthoritative);
      expect(authRecords, isNotEmpty);

      // Must have generated road geometry records (Confidence B)
      final geomRecords = records.where((r) => r.confidence == ProvenanceConfidence.bStrongIndependent);
      expect(geomRecords, isNotEmpty);

      // Must have simulated telemetry disclosures (Confidence E)
      final simRecords = records.where((r) => r.confidence == ProvenanceConfidence.eSimulatedOrGenerated);
      expect(simRecords, isNotEmpty);
    });

    test('Route search matches genuine Goa GTFS locations', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(routesListProvider.future);

      // Search for 'Old Secretariat'
      container
          .read(routeFilterProvider.notifier)
          .setSearchQuery('Old Secretariat');
      var results = container.read(filteredRoutesProvider).value!;
      expect(results.any((r) => r.id == 'R1' || r.id == 'B1'), isTrue);

      // Search for 'Ferry'
      container.read(routeFilterProvider.notifier).setSearchQuery('Ferry');
      results = container.read(filteredRoutesProvider).value!;
      expect(results.any((r) => r.id == 'R1' || r.id == 'B1'), isTrue);

      // Search for 'Mapusa'
      container.read(routeFilterProvider.notifier).setSearchQuery('Mapusa');
      results = container.read(filteredRoutesProvider).value!;
      expect(results.any((r) => r.id == 'PNJ7'), isTrue);

      // Search for 'Margao'
      container.read(routeFilterProvider.notifier).setSearchQuery('Margao');
      results = container.read(filteredRoutesProvider).value!;
      expect(results.any((r) => r.id == 'MRG1'), isTrue);
    });

    test('City filtering categorizes authentic regional routes', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(routesListProvider.future);

      // Filter by 'Mapusa'
      container.read(routeFilterProvider.notifier).setSelectedCity('Mapusa');
      var mapusaRoutes = container.read(filteredRoutesProvider).value!;
      expect(mapusaRoutes.any((r) => r.id == 'PNJ7'), isTrue);

      // Filter by 'Margao'
      container.read(routeFilterProvider.notifier).setSelectedCity('Margao');
      var margaoRoutes = container.read(filteredRoutesProvider).value!;
      expect(margaoRoutes.any((r) => r.id == 'MRG1'), isTrue);

      // Filter by 'Vasco'
      container.read(routeFilterProvider.notifier).setSelectedCity('Vasco');
      var vascoRoutes = container.read(filteredRoutesProvider).value!;
      expect(vascoRoutes.any((r) => r.id == 'MRG11'), isTrue);

      // Filter by 'Panaji'
      container.read(routeFilterProvider.notifier).setSelectedCity('Panaji');
      var panajiRoutes = container.read(filteredRoutesProvider).value!;
      expect(panajiRoutes.any((r) => r.id == 'R1'), isTrue);
      expect(panajiRoutes.any((r) => r.id == 'B1'), isTrue);
    });

    test('Fallback mockRouteDataSourceProvider remains functional for tests',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mockSource = container.read(mockRouteDataSourceProvider);
      final routes = await mockSource.getRoutes();

      expect(routes.length, 3);
      expect(routes.map((r) => r.id).toList(), ['r1', 'r2', 'r3']);
    });
  });
}
