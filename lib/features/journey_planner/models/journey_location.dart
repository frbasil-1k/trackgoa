import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

enum JourneyLocationType {
  currentLocation,
  verifiedStop,
  landmarkPlace,
  cityHub,
  geocodedPlace,
  custom,
}

/// Represents an origin or destination location for transit journey planning.
@immutable
class JourneyLocation {
  const JourneyLocation({
    required this.name,
    required this.coordinate,
    this.type = JourneyLocationType.custom,
    this.subtitle,
    this.isCurrentLocation = false,
    this.isApproximate = false,
    this.isExternallyResolved = false,
    this.address,
    this.stopId,
    this.routeId,
  });

  final String name;
  final String? subtitle;
  final LatLng coordinate;
  final JourneyLocationType type;
  final bool isCurrentLocation;
  final bool isApproximate;
  final bool isExternallyResolved;
  final String? address;
  final String? stopId;
  final String? routeId;

  bool get isVerifiedStop => type == JourneyLocationType.verifiedStop;
  bool get isTransitHub => type == JourneyLocationType.cityHub;
  bool get isLandmark => type == JourneyLocationType.landmarkPlace;
  bool get isGeocoded =>
      type == JourneyLocationType.geocodedPlace || isExternallyResolved;

  String get provenanceLabel {
    if (isCurrentLocation) return 'GPS Location';
    if (isVerifiedStop) return 'Verified GTFS Stop';
    if (isTransitHub) return 'Verified Transit Hub';
    if (isLandmark) return 'Verified Landmark';
    if (isGeocoded) return 'Resolved Place';
    return 'Custom Location';
  }

  JourneyLocation copyWith({
    String? name,
    String? subtitle,
    LatLng? coordinate,
    JourneyLocationType? type,
    bool? isCurrentLocation,
    bool? isApproximate,
    bool? isExternallyResolved,
    String? address,
    String? stopId,
    String? routeId,
  }) {
    return JourneyLocation(
      name: name ?? this.name,
      coordinate: coordinate ?? this.coordinate,
      type: type ?? this.type,
      subtitle: subtitle ?? this.subtitle,
      isCurrentLocation: isCurrentLocation ?? this.isCurrentLocation,
      isApproximate: isApproximate ?? this.isApproximate,
      isExternallyResolved: isExternallyResolved ?? this.isExternallyResolved,
      address: address ?? this.address,
      stopId: stopId ?? this.stopId,
      routeId: routeId ?? this.routeId,
    );
  }

  /// Default fallback location in Goa when GPS permission is not granted (Panaji KTC).
  static const fallbackOrigin = JourneyLocation(
    name: 'Panaji KTC Bus Stand',
    subtitle: 'State Capital Central Bus Terminal',
    coordinate: LatLng(15.49632, 73.8364),
    type: JourneyLocationType.cityHub,
    isApproximate: true,
  );

  /// Key verified places and transit hubs across Goa for quick search & demo scenarios.
  static const List<JourneyLocation> prominentPlaces = [
    JourneyLocation(
      name: 'Fatorda',
      subtitle: 'Fatorda Stadium & Sports Complex, Margao',
      coordinate: LatLng(15.2906, 73.9635),
      type: JourneyLocationType.landmarkPlace,
    ),
    JourneyLocation(
      name: 'Vasco',
      subtitle: 'Vasco KTC Bus Stand & Port Terminal',
      coordinate: LatLng(15.4003, 73.8207),
      type: JourneyLocationType.cityHub,
    ),
    JourneyLocation(
      name: 'Margao',
      subtitle: 'Margao KTC Bus Stand Central Hub',
      coordinate: LatLng(15.28785, 73.95537),
      type: JourneyLocationType.cityHub,
    ),
    JourneyLocation(
      name: 'Panaji',
      subtitle: 'Panaji KTC Bus Stand Central Hub',
      coordinate: LatLng(15.49632, 73.8364),
      type: JourneyLocationType.cityHub,
    ),
    JourneyLocation(
      name: 'Mapusa',
      subtitle: 'Mapusa KTC Bus Stand North Goa Hub',
      coordinate: LatLng(15.5925, 73.8152),
      type: JourneyLocationType.cityHub,
    ),
    JourneyLocation(
      name: 'Dona Paula',
      subtitle: 'Dona Paula Circle & Jetty, Panaji',
      coordinate: LatLng(15.4542, 73.8055),
      type: JourneyLocationType.landmarkPlace,
    ),
    JourneyLocation(
      name: 'Cortalim Junction',
      subtitle: 'Zuari Bridge Transit Transfer Interchange',
      coordinate: LatLng(15.4095, 73.9055),
      type: JourneyLocationType.landmarkPlace,
    ),
    JourneyLocation(
      name: 'GMC Bambolim',
      subtitle: 'Goa Medical College Hospital',
      coordinate: LatLng(15.4610, 73.8580),
      type: JourneyLocationType.landmarkPlace,
    ),
    JourneyLocation(
      name: 'Carmel College',
      subtitle: 'Carmel College for Women, Nuvem',
      coordinate: LatLng(15.31158, 73.94415),
      type: JourneyLocationType.landmarkPlace,
    ),
    JourneyLocation(
      name: 'Taleigao',
      subtitle: 'Taleigao Church & Market, Panaji',
      coordinate: LatLng(15.4720, 73.8280),
      type: JourneyLocationType.landmarkPlace,
    ),
  ];

  @override
  bool operator ==(Object other) =>
      other is JourneyLocation &&
      name == other.name &&
      coordinate.latitude == other.coordinate.latitude &&
      coordinate.longitude == other.coordinate.longitude &&
      isCurrentLocation == other.isCurrentLocation;

  @override
  int get hashCode => Object.hash(
        name,
        coordinate.latitude,
        coordinate.longitude,
        isCurrentLocation,
      );

  @override
  String toString() =>
      'JourneyLocation($name, ${coordinate.latitude}, ${coordinate.longitude})';
}
