import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// Core deployment configuration for the SMART platform.
///
/// Each SMART deployment (SMART-GO, SMART-KA, SMART-MH, etc.) is defined by
/// a single [SmartDeployment] instance that provides all region-specific
/// configuration. This keeps region-specific assumptions out of the platform
/// core code.
///
/// Usage:
/// ```dart
/// // In main.dart for SMART-GO
/// final deployment = SmartGoDeployment();
/// runApp(ProviderScope(
///   overrides: [deploymentProvider.overrideWithValue(deployment)],
///   child: const SmartGoApp(),
/// ));
/// ```
@immutable
class SmartDeployment {
  const SmartDeployment({
    required this.id,
    required this.displayName,
    required this.region,
    required this.tagline,
    required this.defaultCenter,
    required this.defaultZoom,
    required this.defaultBoundsNE,
    required this.defaultBoundsSW,
    required this.defaultLocale,
    required this.networks,
    required this.cities,
    required this.defaultCity,
  });

  /// Unique deployment identifier (e.g. 'smart-go').
  final String id;

  /// Human-readable deployment name (e.g. 'SMART-GO').
  final String displayName;

  /// Geographic region this deployment covers (e.g. 'Goa').
  final String region;

  /// Tagline shown on the home screen.
  final String tagline;

  /// Default map center when the app opens.
  final LatLng defaultCenter;

  /// Default map zoom level.
  final double defaultZoom;

  /// Northeast corner of the deployment's geographic bounds.
  final LatLng defaultBoundsNE;

  /// Southwest corner of the deployment's geographic bounds.
  final LatLng defaultBoundsSW;

  /// Default locale code (e.g. 'en_IN').
  final String defaultLocale;

  /// Transit networks available in this deployment.
  final List<TransitNetwork> networks;

  /// Cities available for filtering in this deployment.
  final List<String> cities;

  /// Default city for new users.
  final String defaultCity;
}

/// Supported transportation modes.
enum TransitMode {
  bus,
  ferry,
  metro,
  train,
  rickshaw;

  String get displayName {
    switch (this) {
      case TransitMode.bus:
        return 'Bus';
      case TransitMode.ferry:
        return 'Ferry';
      case TransitMode.metro:
        return 'Metro';
      case TransitMode.train:
        return 'Train';
      case TransitMode.rickshaw:
        return 'Rickshaw';
    }
  }
}

/// A transit network within a deployment (e.g. Kadamba Transport Corporation).
@immutable
class TransitNetwork {
  const TransitNetwork({
    required this.id,
    required this.name,
    required this.operatorName,
    required this.primaryMode,
    this.supportedModes = const [],
  });

  /// Unique network identifier.
  final String id;

  /// Human-readable network name.
  final String name;

  /// Name of the operating entity.
  final String operatorName;

  /// The primary transportation mode.
  final TransitMode primaryMode;

  /// All supported modes (including primary).
  final List<TransitMode> supportedModes;
}
