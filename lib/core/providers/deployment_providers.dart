import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/deployment.dart';
import '../../deployments/smart_go/smart_go_deployment.dart';

/// Global deployment provider.
///
/// Defaults to SMART-GO. Override in ProviderScope for other deployments.
/// All UI components that need region-specific values (city list, tagline,
/// map bounds, etc.) should read from this provider instead of hard-coding.
final deploymentProvider = Provider<SmartDeployment>((ref) {
  return smartGoDeployment;
});

/// Convenience: deployment display name (e.g. 'SMART-GO').
final deploymentNameProvider = Provider<String>((ref) {
  return ref.watch(deploymentProvider).displayName;
});

/// Convenience: list of cities available for filtering.
final deploymentCitiesProvider = Provider<List<String>>((ref) {
  return ref.watch(deploymentProvider).cities;
});

/// Convenience: default city for new users.
final defaultCityProvider = Provider<String>((ref) {
  return ref.watch(deploymentProvider).defaultCity;
});

/// Convenience: deployment region name (e.g. 'Goa').
final deploymentRegionProvider = Provider<String>((ref) {
  return ref.watch(deploymentProvider).region;
});
