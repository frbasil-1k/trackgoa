import '../models/prediction_insight.dart';
import '../models/route_analytics.dart';

/// Read-only Phase 2 analytics fixtures for the three demo routes.
const mockRouteAnalytics = [
  RouteAnalytics(
    routeId: 'r1',
    averageDelayMinutes: 3.2,
    onTimePercentage: 87,
    reliabilityScore: 84,
    peakPeriod: '08:00–10:00',
    sampleWindow: 'Last 7 days',
  ),
  RouteAnalytics(
    routeId: 'r2',
    averageDelayMinutes: 2.1,
    onTimePercentage: 91,
    reliabilityScore: 89,
    peakPeriod: '17:30–19:30',
    sampleWindow: 'Last 7 days',
  ),
  RouteAnalytics(
    routeId: 'r3',
    averageDelayMinutes: 2.8,
    onTimePercentage: 89,
    reliabilityScore: 86,
    peakPeriod: '08:30–10:30',
    sampleWindow: 'Last 7 days',
  ),
];

const mockPredictionInsights = [
  PredictionInsight(
    routeId: 'r1',
    type: PredictionInsightType.likelyDelay,
    confidence: 0.78,
    message: 'R1 is likely to slow near St. Inez during the morning peak.',
  ),
  PredictionInsight(
    routeId: 'r2',
    type: PredictionInsightType.busiestStop,
    confidence: 0.72,
    message: 'Fatorda Church is the busiest upcoming stop in the evening.',
  ),
  PredictionInsight(
    routeId: 'r3',
    type: PredictionInsightType.serviceImprovement,
    confidence: 0.68,
    message: 'R3 reliability improves outside airport traffic periods.',
  ),
];
