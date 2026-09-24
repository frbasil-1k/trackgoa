import 'package:latlong2/latlong.dart';

import '../../core/models/deployment.dart';

/// SMART-GO deployment configuration for Goa, India.
///
/// This is the first deployment of the SMART platform. All Goa-specific
/// values (cities, map bounds, operator info) are defined here rather than
/// scattered throughout the codebase.
const smartGoDeployment = SmartDeployment(
  id: 'smart-go',
  displayName: 'SMART-GO',
  region: 'Goa',
  tagline: 'Navigate Goa, effortlessly.',
  defaultCenter: LatLng(15.4909, 73.8278), // Panaji city center
  defaultZoom: 12.0,
  defaultBoundsNE: LatLng(15.80, 74.10), // Goa NE corner
  defaultBoundsSW: LatLng(14.90, 73.70), // Goa SW corner
  defaultLocale: 'en_IN',
  defaultCity: 'Panaji',
  cities: [
    'Panaji',
    'Margao',
    'Vasco',
    'Mapusa',
    'Ponda',
    'Miramar',
  ],
  networks: [
    TransitNetwork(
      id: 'ktc',
      name: 'Kadamba Transport Corporation',
      operatorName: 'KTC',
      primaryMode: TransitMode.bus,
      supportedModes: [TransitMode.bus],
    ),
  ],
);
