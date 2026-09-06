import '../models/analytics_model.dart';

/// Phase 6.4 — Read-only analytics repository.
///
/// Supplies [AnalyticsBundle] per route. The interface mirrors what a future
/// PostgreSQL-backed REST or GraphQL endpoint would return, making the swap-in
/// a matter of replacing this with a real data source.
abstract class AnalyticsRepository {
  const AnalyticsRepository();

  /// Returns all available analytics bundles (one per route).
  Future<List<AnalyticsBundle>> getAllAnalytics();

  /// Returns analytics for a specific route, or null if not found.
  Future<AnalyticsBundle?> getAnalyticsForRoute(String routeId);
}

/// Mock implementation that returns deterministic fixtures matching the
/// Phase 6.4 dataset:
///
/// R1 Panaji–Miramar  → 94% on-time, 2 min avg delay, 96 reliability, 5–7 PM peak
/// R2 Margao–Fatorda → 88% on-time, 4 min avg delay, 90 reliability
/// R3 Vasco–Chicalim → 91% on-time, 3 min avg delay, 93 reliability
class MockAnalyticsRepository implements AnalyticsRepository {
  const MockAnalyticsRepository();

  static final List<AnalyticsBundle> _bundles = _fixtureBundles();

  @override
  Future<List<AnalyticsBundle>> getAllAnalytics() async => _bundles;

  @override
  Future<AnalyticsBundle?> getAnalyticsForRoute(String routeId) async {
    return _bundles.cast<AnalyticsBundle?>().firstWhere(
      (b) => b?.routeId == routeId,
      orElse: () => null,
    );
  }
}

/// Deterministic mock fixtures, computed once at library load.
List<AnalyticsBundle> _fixtureBundles() {
  return [
    AnalyticsBundle(
      routeId: 'r1',
      routeName: 'R1 — Panaji ↔ Miramar',
      routeShortName: 'R1',
      origin: 'Panaji',
      destination: 'Miramar',
      color: 0xFF00897B,
      onTimePercentage: 94,
      averageDelayMinutes: 2,
      reliabilityScore: 96,
      peakPeriod: '5–7 PM',
      sampleWindow: 'Last 7 days',
      reliabilityTrend: const [
        TrendPoint(label: 'Mon', value: 93),
        TrendPoint(label: 'Tue', value: 95),
        TrendPoint(label: 'Wed', value: 94),
        TrendPoint(label: 'Thu', value: 96),
        TrendPoint(label: 'Fri', value: 91),
        TrendPoint(label: 'Sat', value: 98),
        TrendPoint(label: 'Sun', value: 97),
      ],
    ),
    AnalyticsBundle(
      routeId: 'r2',
      routeName: 'R2 — Margao ↔ Fatorda',
      routeShortName: 'R2',
      origin: 'Margao',
      destination: 'Fatorda',
      color: 0xFFE65100,
      onTimePercentage: 88,
      averageDelayMinutes: 4,
      reliabilityScore: 90,
      peakPeriod: '8–10 AM',
      sampleWindow: 'Last 7 days',
      reliabilityTrend: const [
        TrendPoint(label: 'Mon', value: 87),
        TrendPoint(label: 'Tue', value: 89),
        TrendPoint(label: 'Wed', value: 91),
        TrendPoint(label: 'Thu', value: 88),
        TrendPoint(label: 'Fri', value: 85),
        TrendPoint(label: 'Sat', value: 92),
        TrendPoint(label: 'Sun', value: 94),
      ],
    ),
    AnalyticsBundle(
      routeId: 'r3',
      routeName: 'R3 — Vasco ↔ Chicalim',
      routeShortName: 'R3',
      origin: 'Vasco',
      destination: 'Chicalim',
      color: 0xFF1565C0,
      onTimePercentage: 91,
      averageDelayMinutes: 3,
      reliabilityScore: 93,
      peakPeriod: '12–2 PM',
      sampleWindow: 'Last 7 days',
      reliabilityTrend: const [
        TrendPoint(label: 'Mon', value: 90),
        TrendPoint(label: 'Tue', value: 93),
        TrendPoint(label: 'Wed', value: 91),
        TrendPoint(label: 'Thu', value: 94),
        TrendPoint(label: 'Fri', value: 92),
        TrendPoint(label: 'Sat', value: 95),
        TrendPoint(label: 'Sun', value: 96),
      ],
    ),
  ];
}
