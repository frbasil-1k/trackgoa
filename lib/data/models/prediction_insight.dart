import 'package:flutter/foundation.dart';

/// Categories of future route predictions; values are supplied by data sources.
enum PredictionInsightType { likelyDelay, busiestStop, serviceImprovement }

/// A read-only, route-scoped prediction or operational insight.
@immutable
class PredictionInsight {
  const PredictionInsight({
    required this.routeId,
    required this.type,
    required this.confidence,
    required this.message,
  });

  final String routeId;
  final PredictionInsightType type;
  final double confidence;
  final String message;

  PredictionInsight copyWith({
    String? routeId,
    PredictionInsightType? type,
    double? confidence,
    String? message,
  }) => PredictionInsight(
    routeId: routeId ?? this.routeId,
    type: type ?? this.type,
    confidence: confidence ?? this.confidence,
    message: message ?? this.message,
  );

  @override
  bool operator ==(Object other) =>
      other is PredictionInsight &&
      routeId == other.routeId &&
      type == other.type &&
      confidence == other.confidence &&
      message == other.message;

  @override
  int get hashCode => Object.hash(routeId, type, confidence, message);
}
