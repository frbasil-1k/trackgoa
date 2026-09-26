import 'package:flutter/foundation.dart';

/// Real-time passenger crowding classification for transit vehicles.
enum VehicleCrowding {
  low,
  moderate,
  standingRoomOnly,
}

extension VehicleCrowdingX on VehicleCrowding {
  String get passengerLabel {
    switch (this) {
      case VehicleCrowding.low:
        return 'Many seats available';
      case VehicleCrowding.moderate:
        return 'Few seats available';
      case VehicleCrowding.standingRoomOnly:
        return 'Standing room only';
    }
  }

  String get shortLabel {
    switch (this) {
      case VehicleCrowding.low:
        return 'Low Crowding';
      case VehicleCrowding.moderate:
        return 'Moderate';
      case VehicleCrowding.standingRoomOnly:
        return 'Crowded';
    }
  }
}

/// Stable passenger-facing bus and fleet metadata; live location and telemetry
/// are held by [BusPosition].
@immutable
class BusModel {
  const BusModel({
    required this.id,
    required this.routeId,
    required this.label,
    this.registrationNumber,
    this.vehicleModel,
    this.chassis,
    this.operatorName,
    this.isVerifiedFleetAsset = true,
    this.capacity = 32,
    this.vehicleType = 'Electric AC City Shuttle',
    this.isElectric = true,
    this.isAirConditioned = true,
    this.isWheelchairAccessible = true,
    this.crowding = VehicleCrowding.low,
    this.isSimulated = true,
  });

  final String id;
  final String routeId;
  final String label;
  final String? registrationNumber;
  final String? vehicleModel;
  final String? chassis;
  final String? operatorName;
  final bool isVerifiedFleetAsset;
  final int? capacity;
  final String? vehicleType;
  final bool isElectric;
  final bool isAirConditioned;
  final bool isWheelchairAccessible;
  final VehicleCrowding crowding;
  final bool isSimulated;

  BusModel copyWith({
    String? id,
    String? routeId,
    String? label,
    String? registrationNumber,
    String? vehicleModel,
    String? chassis,
    String? operatorName,
    bool? isVerifiedFleetAsset,
    int? capacity,
    String? vehicleType,
    bool? isElectric,
    bool? isAirConditioned,
    bool? isWheelchairAccessible,
    VehicleCrowding? crowding,
    bool? isSimulated,
  }) => BusModel(
    id: id ?? this.id,
    routeId: routeId ?? this.routeId,
    label: label ?? this.label,
    registrationNumber: registrationNumber ?? this.registrationNumber,
    vehicleModel: vehicleModel ?? this.vehicleModel,
    chassis: chassis ?? this.chassis,
    operatorName: operatorName ?? this.operatorName,
    isVerifiedFleetAsset: isVerifiedFleetAsset ?? this.isVerifiedFleetAsset,
    capacity: capacity ?? this.capacity,
    vehicleType: vehicleType ?? this.vehicleType,
    isElectric: isElectric ?? this.isElectric,
    isAirConditioned: isAirConditioned ?? this.isAirConditioned,
    isWheelchairAccessible:
        isWheelchairAccessible ?? this.isWheelchairAccessible,
    crowding: crowding ?? this.crowding,
    isSimulated: isSimulated ?? this.isSimulated,
  );

  @override
  bool operator ==(Object other) =>
      other is BusModel &&
      id == other.id &&
      routeId == other.routeId &&
      label == other.label &&
      registrationNumber == other.registrationNumber &&
      vehicleModel == other.vehicleModel &&
      chassis == other.chassis &&
      operatorName == other.operatorName &&
      isVerifiedFleetAsset == other.isVerifiedFleetAsset &&
      capacity == other.capacity &&
      vehicleType == other.vehicleType &&
      isElectric == other.isElectric &&
      isAirConditioned == other.isAirConditioned &&
      isWheelchairAccessible == other.isWheelchairAccessible &&
      crowding == other.crowding &&
      isSimulated == other.isSimulated;

  @override
  int get hashCode => Object.hash(
    id,
    routeId,
    label,
    registrationNumber,
    vehicleModel,
    chassis,
    operatorName,
    isVerifiedFleetAsset,
    capacity,
    vehicleType,
    isElectric,
    isAirConditioned,
    isWheelchairAccessible,
    crowding,
    isSimulated,
  );
}
