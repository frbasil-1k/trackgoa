import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../data/models/alert_model.dart';
import '../../../data/models/stop_model.dart';
import '../../../data/repositories/repository_providers.dart';
import 'map_providers.dart';
import '../services/eta_calculation_service.dart';

/// Singleton instance of the pure ETA calculation service.
///
/// Stateless — all methods are pure functions of their arguments.
final etaCalculationServiceProvider = Provider<EtaCalculationService>(
  (ref) => const EtaCalculationService(),
);

/// Provides a [Stream] of [StopProgress] for every stop on a route,
/// updated every simulation tick (500 ms).
///
/// Uses [selectedStopId] to determine which stop the user is tracking
/// for alert purposes.
///
/// Emits an empty list if the route has not been warmed up yet.
final liveStopsProvider =
    StreamProvider.family<List<StopProgress>, String>((ref, routeId) {
  final engine = ref.watch(busSimulationEngineProvider);
  final etaService = ref.watch(etaCalculationServiceProvider);
  final routeAsync = ref.watch(selectedRouteProvider(routeId));

  // Get the route's stops for looking up stop data.
  final route = routeAsync.value;

  return engine.positionsStream.map((allPositions) {
    final positions = allPositions
        .where((p) => p.busId.startsWith('$routeId-'))
        .toList(growable: false);

    if (route == null || route.stops.isEmpty) return const <StopProgress>[];

    // Use the first bus on this route for all stop progress calculations.
    final busPosition = positions.isNotEmpty ? positions.first : null;

    final progress = etaService.computeStopsProgress(
      route: route,
      busPosition: busPosition,
    );

    return progress;
  });
});

/// Provides a [Stream] of the next upcoming stop for a route.
///
/// Returns null when the route has not been warmed up or has no stops.
final nextStopProvider =
    Provider.family<StopModel?, String>((ref, routeId) {
  return ref.watch(routeProgressSummaryProvider(routeId)).maybeWhen(
        data: (summary) => summary?.nextStop,
        orElse: () => null,
      );
});

/// Provides a [Stream] of the live [RouteProgressSummary] for a route.
///
/// This is the main provider the bottom sheet consumes. Updated every
/// simulation tick so the ETA, next stop, speed, and stops remaining
/// are always current.
final routeProgressSummaryProvider =
    StreamProvider.family<RouteProgressSummary?, String>((ref, routeId) {
  final engine = ref.watch(busSimulationEngineProvider);
  final etaService = ref.watch(etaCalculationServiceProvider);
  final routeAsync = ref.watch(selectedRouteProvider(routeId));

  return engine.positionsStream.map((allPositions) {
    final positions = allPositions
        .where((p) => p.busId.startsWith('$routeId-'))
        .toList(growable: false);

    final route = routeAsync.value;
    if (route == null || route.stops.isEmpty) return null;

    final busPosition = positions.isNotEmpty ? positions.first : null;
    return etaService.computeRouteProgressSummary(
      route: route,
      busPosition: busPosition,
    );
  });
});

/// Provider family tracking which stop the user has selected for alerts.
///
/// Defaults to null; the tracking screen sets this when a stop is tapped.
final selectedStopIdProvider = StateProvider.family<String?, String>((ref, routeId) {
  // Default to null; the tracking screen sets this when a stop is tapped.
  return null;
});

/// Provides accumulated alert events for the selected stop on a route.
///
/// Uses [LiveAlertService] internally to track threshold crossings.
final alertsProvider = StateProvider.family<List<AlertModel>, String>(
  (ref, routeId) => const [],
);

/// State notifier that tracks alert thresholds and emits [AlertModel]
/// events when they are crossed.
///
/// Uses [liveStopsProvider] internally and compares [stopsAway]
/// against the selected stop to determine when to fire alerts.
///
/// Architecture note: this uses a [ChangeNotifier] + Riverpod pattern
/// so it can be listened to from the UI and emits are automatically
/// propagated to the [alertsProvider] consumer.
class AlertStateTracker extends ChangeNotifier {
  AlertStateTracker({
    required this.routeId,
    required this.etaService,
  });

  final String routeId;
  final EtaCalculationService etaService;
  final _alerts = <AlertModel>[];
  final _seenAlertKeys = <String>{};
  String? _selectedStopId;

  /// The accumulated list of alert events.
  List<AlertModel> get alerts => List.unmodifiable(_alerts);

  /// Process a new set of [StopProgress] and emit alerts when
  /// thresholds are crossed.
  void processStopsProgress(List<StopProgress> stopsProgress) {
    if (_selectedStopId == null) return;

    // Find the selected stop's progress.
    final selectedProgress = stopsProgress.firstWhere(
      (sp) => sp.stop.id == _selectedStopId,
      orElse: () => throw Exception('Selected stop not found in progress list'),
    );

    // Determine alert type based on stopsAway.
    final alertType = _determineAlertType(selectedProgress);
    if (alertType == null) return;

    final alertKey = '$routeId-${selectedProgress.stop.id}-$alertType';
    if (_seenAlertKeys.contains(alertKey)) return;

    _seenAlertKeys.add(alertKey);

    final alert = AlertModel(
      id: alertKey,
      busId: routeId,
      routeId: routeId,
      stopId: selectedProgress.stop.id,
      type: alertType,
      createdAt: DateTime.now(),
      message: _buildAlertMessage(alertType, selectedProgress.stop.name),
    );
    _alerts.add(alert);
    notifyListeners();
  }

  void setSelectedStop(String? stopId) {
    if (_selectedStopId == stopId) return;
    _selectedStopId = stopId;
    _seenAlertKeys.clear();
    notifyListeners();
  }

  AlertType? _determineAlertType(StopProgress progress) {
    if (progress.state == StopProgressState.current ||
        progress.state == StopProgressState.passed) {
      return AlertType.reached;
    }
    if (progress.stopsAway == 1) {
      return AlertType.oneStopAway;
    }
    if (progress.stopsAway == 2) {
      return AlertType.twoStopsAway;
    }
    return null;
  }

  String _buildAlertMessage(AlertType type, String stopName) {
    switch (type) {
      case AlertType.twoStopsAway:
        return '$stopName is 2 stops away';
      case AlertType.oneStopAway:
        return '🚏 $stopName is 1 stop away!';
      case AlertType.reached:
        return '🎉 Arrived at $stopName!';
      case AlertType.delayed:
        return 'Delay detected at $stopName';
      case AlertType.slowdown:
        return 'Slowdown near $stopName';
    }
  }
}

/// Riverpod provider that creates and manages an [AlertStateTracker] for each route.
final alertStateTrackerProvider =
    ChangeNotifierProvider.family<AlertStateTracker, String>((ref, routeId) {
  final etaService = ref.watch(etaCalculationServiceProvider);
  return AlertStateTracker(
    routeId: routeId,
    etaService: etaService,
  );
});