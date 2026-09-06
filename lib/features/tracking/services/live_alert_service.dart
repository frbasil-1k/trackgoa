import '../../../data/models/alert_model.dart';
import 'eta_calculation_service.dart';

/// Phase 6.3 — Live alert service that fires snackbar notifications when
/// a bus crosses alert thresholds for the user's selected stop.
///
/// Architecture note: This is a pure Dart class with no Riverpod dependency.
/// It receives [StopProgress] updates from a provider subscription and
/// emits [AlertModel] events. This design keeps the service testable and
/// compatible with any state-management approach.
class LiveAlertService {
  LiveAlertService({required this.onAlert}) {
    _seenKeys.clear();
    _lastStopsAway.clear();
  }

  final void Function(AlertModel alert) onAlert;
  final _seenKeys = <String>{};
  final _lastStopsAway = <String, int>{};

  /// Process a new set of [StopProgress] for a route and fire alerts
  /// when thresholds are crossed.
  void processStopsProgress({
    required String routeId,
    required String? selectedStopId,
    required List<StopProgress> stopsProgress,
  }) {
    if (selectedStopId == null) return;

    // Find the selected stop's progress.
    StopProgress? selectedProgress;
    for (final sp in stopsProgress) {
      if (sp.stop.id == selectedStopId) {
        selectedProgress = sp;
        break;
      }
    }

    if (selectedProgress == null) return;
    final sp = selectedProgress;

    final stopId = sp.stop.id;
    final stopsAway = sp.stopsAway;
    final state = sp.state;

    // Track previous stopsAway to detect transitions.
    final previousStopsAway = _lastStopsAway[stopId] ?? -999;
    _lastStopsAway[stopId] = stopsAway;

    // Fire alerts based on threshold crossings.
    AlertModel? alert;

    if (state == StopProgressState.current) {
      alert = _fireIfNew('reached-$stopId', () => AlertModel(
        id: 'alert-${DateTime.now().millisecondsSinceEpoch}',
        busId: routeId,
        routeId: routeId,
        stopId: stopId,
        type: AlertType.reached,
        createdAt: DateTime.now(),
        message: '🎉 Arrived at ${sp.stop.name}!',
      ));
    } else if (previousStopsAway == 2 && stopsAway < 2) {
      alert = _fireIfNew('twoStopsAway-$stopId', () => AlertModel(
        id: 'alert-${DateTime.now().millisecondsSinceEpoch}',
        busId: routeId,
        routeId: routeId,
        stopId: stopId,
        type: AlertType.twoStopsAway,
        createdAt: DateTime.now(),
        message: '${sp.stop.name} is 2 stops away',
      ));
    } else if (previousStopsAway == 1 && stopsAway < 1) {
      alert = _fireIfNew('oneStopAway-$stopId', () => AlertModel(
        id: 'alert-${DateTime.now().millisecondsSinceEpoch}',
        busId: routeId,
        routeId: routeId,
        stopId: stopId,
        type: AlertType.oneStopAway,
        createdAt: DateTime.now(),
        message: '🚏 ${sp.stop.name} is 1 stop away!',
      ));
    }

    if (alert != null) {
      onAlert(alert);
    }

    // Reset tracking when bus moves away from thresholds.
    if (stopsAway > 2 && previousStopsAway <= 2) {
      _seenKeys.remove('twoStopsAway-$stopId');
      _seenKeys.remove('oneStopAway-$stopId');
      _seenKeys.remove('reached-$stopId');
      _lastStopsAway.remove(stopId);
    }
  }

  AlertModel? _fireIfNew(String key, AlertModel Function() factory) {
    if (_seenKeys.contains(key)) return null;
    _seenKeys.add(key);
    return factory();
  }

  /// Resets alert state when the user selects a different stop.
  void resetForStop(String stopId) {
    _seenKeys.remove('twoStopsAway-$stopId');
    _seenKeys.remove('oneStopAway-$stopId');
    _seenKeys.remove('reached-$stopId');
    _lastStopsAway.remove(stopId);
  }

  /// Clears all alert state.
  void reset() {
    _seenKeys.clear();
    _lastStopsAway.clear();
  }
}
