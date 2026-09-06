import 'package:flutter/foundation.dart';

/// A single reliability data point for a given day.
///
/// Used by the lightweight 7-day reliability trend chart.
@immutable
class TrendPoint {
  const TrendPoint({required this.label, required this.value});
  final String label; // e.g. 'Mon'
  final double value; // 0..100
}

/// Severity bucket for AI prediction insights.
///
/// Used to color-code the prediction card and pick a confidence chip.
enum InsightSeverity { info, warning, critical }

/// Severity-aware AI prediction insight.
///
/// Extends the existing [PredictionInsight] model with route name + severity so
/// the analytics screen can render premium insight cards without consulting
/// any other source.
@immutable
class AnalyticsInsight {
  const AnalyticsInsight({
    required this.routeId,
    required this.routeName,
    required this.title,
    required this.message,
    required this.severity,
    required this.confidence,
  });

  final String routeId;
  final String routeName;
  final String title;
  final String message;
  final InsightSeverity severity;
  final double confidence; // 0..1
}

/// The aggregate analytics payload for a single route, returned by
/// [AnalyticsRepository.getAnalyticsForRoute].
///
/// Includes the existing [RouteAnalytics] shape plus trend and status
/// metadata needed for the dashboard.
@immutable
class AnalyticsBundle {
  const AnalyticsBundle({
    required this.routeId,
    required this.routeName,
    required this.routeShortName,
    required this.origin,
    required this.destination,
    required this.color,
    required this.onTimePercentage,
    required this.averageDelayMinutes,
    required this.reliabilityScore,
    required this.peakPeriod,
    required this.sampleWindow,
    required this.reliabilityTrend,
  });

  final String routeId;
  final String routeName;
  final String routeShortName;
  final String origin;
  final String destination;
  final int color; // ARGB; passed by value to keep model pure-Dart.
  final double onTimePercentage;
  final double averageDelayMinutes;
  final double reliabilityScore;
  final String peakPeriod;
  final String sampleWindow;
  final List<TrendPoint> reliabilityTrend;
}
