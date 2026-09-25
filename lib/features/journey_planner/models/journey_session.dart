import 'package:flutter/foundation.dart';
import 'journey_leg.dart';
import 'journey_location.dart';
import 'journey_option.dart';

/// Explicit lifecycle states of a passenger executing a journey.
enum JourneyProgressState {
  planning,
  journeySelected,
  walkingToFirstStop,
  waitingForBus,
  onBus,
  approachingTransfer,
  atTransfer,
  waitingForNextBus,
  onNextBus,
  approachingDestination,
  arrived,
}

/// Active execution context for a passenger tracking their multimodal journey.
@immutable
class ActiveJourneySession {
  const ActiveJourneySession({
    required this.journey,
    this.currentLegIndex = 0,
    this.currentState = JourneyProgressState.journeySelected,
    this.currentVehicleId,
    required this.finalDestination,
    required this.startedAt,
  });

  final JourneyOption journey;
  final int currentLegIndex;
  final JourneyProgressState currentState;
  final String? currentVehicleId;
  final JourneyLocation finalDestination;
  final DateTime startedAt;

  JourneyLeg get currentLeg => currentLegIndex < journey.legs.length
      ? journey.legs[currentLegIndex]
      : journey.legs.last;

  bool get isMultiLeg => journey.legs.where((l) => l.isTransit).length > 1;

  bool get hasNextLeg => currentLegIndex + 1 < journey.legs.length;

  JourneyLeg? get nextLeg =>
      hasNextLeg ? journey.legs[currentLegIndex + 1] : null;

  JourneyLeg? get nextTransitLeg {
    for (int i = currentLegIndex + 1; i < journey.legs.length; i++) {
      if (journey.legs[i].isTransit) return journey.legs[i];
    }
    return null;
  }

  String get finalDestinationName => finalDestination.name;

  ActiveJourneySession advanceToNextLeg() {
    if (hasNextLeg) {
      final nextIdx = currentLegIndex + 1;
      final next = journey.legs[nextIdx];
      return copyWith(
        currentLegIndex: nextIdx,
        currentVehicleId: next.recommendedVehicle?.id ?? currentVehicleId,
        currentState: next.isTransit
            ? JourneyProgressState.onNextBus
            : (next.isTransfer ? JourneyProgressState.atTransfer : JourneyProgressState.walkingToFirstStop),
      );
    } else {
      return copyWith(currentState: JourneyProgressState.arrived);
    }
  }

  ActiveJourneySession copyWith({
    JourneyOption? journey,
    int? currentLegIndex,
    JourneyProgressState? currentState,
    String? currentVehicleId,
    JourneyLocation? finalDestination,
    DateTime? startedAt,
  }) {
    return ActiveJourneySession(
      journey: journey ?? this.journey,
      currentLegIndex: currentLegIndex ?? this.currentLegIndex,
      currentState: currentState ?? this.currentState,
      currentVehicleId: currentVehicleId ?? this.currentVehicleId,
      finalDestination: finalDestination ?? this.finalDestination,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}
