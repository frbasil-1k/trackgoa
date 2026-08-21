import 'package:flutter/foundation.dart';

/// Read-only route reliability summary, supplied by mock data or a future API.
@immutable
class RouteAnalytics {
  const RouteAnalytics({
    required this.routeId,
    required this.averageDelayMinutes,
    required this.onTimePercentage,
    required this.reliabilityScore,
    required this.peakPeriod,
    required this.sampleWindow,
  });

  final String routeId;
  final double averageDelayMinutes;
  final double onTimePercentage;
  final double reliabilityScore;
  final String peakPeriod;
  final String sampleWindow;

  RouteAnalytics copyWith({
    String? routeId,
    double? averageDelayMinutes,
    double? onTimePercentage,
    double? reliabilityScore,
    String? peakPeriod,
    String? sampleWindow,
  }) => RouteAnalytics(
    routeId: routeId ?? this.routeId,
    averageDelayMinutes: averageDelayMinutes ?? this.averageDelayMinutes,
    onTimePercentage: onTimePercentage ?? this.onTimePercentage,
    reliabilityScore: reliabilityScore ?? this.reliabilityScore,
    peakPeriod: peakPeriod ?? this.peakPeriod,
    sampleWindow: sampleWindow ?? this.sampleWindow,
  );

  @override
  bool operator ==(Object other) =>
      other is RouteAnalytics &&
      routeId == other.routeId &&
      averageDelayMinutes == other.averageDelayMinutes &&
      onTimePercentage == other.onTimePercentage &&
      reliabilityScore == other.reliabilityScore &&
      peakPeriod == other.peakPeriod &&
      sampleWindow == other.sampleWindow;

  @override
  int get hashCode => Object.hash(
    routeId,
    averageDelayMinutes,
    onTimePercentage,
    reliabilityScore,
    peakPeriod,
    sampleWindow,
  );
}
