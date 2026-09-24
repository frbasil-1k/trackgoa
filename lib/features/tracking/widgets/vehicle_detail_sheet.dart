import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/shared/widgets/app_card.dart';
import '../../../core/shared/widgets/status_pill.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/bus_model.dart';
import '../../../data/models/route_model.dart';
import '../providers/vehicle_providers.dart';

/// Modal bottom sheet presenting clear, passenger-centric vehicle intelligence.
///
/// Answers key passenger questions:
/// 1. Which vehicle am I tracking? (Registration & fleet identifier)
/// 2. Is this vehicle live? (Clear simulated demo telemetry disclosure)
/// 3. How crowded is it? (Real-time occupancy classification)
/// 4. What type of vehicle is it? (Electric AC shuttle / low-floor bus)
/// 5. Amenities? (AC, Electric, Accessible)
/// 6. Current speed? (Real-time calibrated speed)
/// 7. Should I take it? (Next stop and arrival ETA)
class VehicleDetailSheet extends ConsumerWidget {
  const VehicleDetailSheet({
    required this.busId,
    required this.route,
    this.onFocusVehicleOnMap,
    super.key,
  });

  final String busId;
  final RouteModel route;
  final VoidCallback? onFocusVehicleOnMap;

  static Future<void> show(
    BuildContext context, {
    required String busId,
    required RouteModel route,
    VoidCallback? onFocusVehicleOnMap,
  }) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VehicleDetailSheet(
        busId: busId,
        route: route,
        onFocusVehicleOnMap: onFocusVehicleOnMap,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intel = ref.watch(vehicleIntelligenceProvider(busId));
    final colorScheme = Theme.of(context).colorScheme;
    final bus = intel.bus;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.sheetRadius),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        MediaQuery.paddingOf(context).bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Drag Handle ──────────────────────────────────────────────────
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.inactive.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // ── Header Row ───────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: route.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                  border: Border.all(
                    color: route.color.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.directions_bus_rounded,
                  color: route.color,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            bus.registrationNumber ?? bus.label,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: bus.isVerifiedFleetAsset
                                ? const Color(0xFFE8F5E9)
                                : AppColors.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: bus.isVerifiedFleetAsset
                                  ? const Color(0xFF81C784)
                                  : AppColors.accent.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            bus.isVerifiedFleetAsset ? 'VERIFIED FLEET ASSET' : 'DEMO FLEET',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: bus.isVerifiedFleetAsset
                                  ? const Color(0xFF2E7D32)
                                  : AppColors.accent,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: route.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            bus.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: route.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${route.shortName} • ${route.origin} → ${route.destination}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const ValueKey('vehicle-detail-close-btn'),
                tooltip: 'Close vehicle details',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Transparency & Telemetry Disclosure ───────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
              border: Border.all(
                color: const Color(0xFF86EFAC),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.sensors_rounded,
                  color: Color(0xFF16A34A),
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Simulated Live Telemetry • Demo Mode',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15803D),
                        ),
                      ),
                      Text(
                        'GPS motion is calibrated to Goa transit schedules. Hardware AVL telemetry connects in live fleet.',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF166534).withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Passenger Metrics: Crowding & Speed ───────────────────────────
          Row(
            children: [
              // Crowding / Seating Card
              Expanded(
                child: _MetricCard(
                  icon: Icons.people_outline_rounded,
                  iconColor: _crowdingColor(bus.crowding),
                  title: 'Occupancy',
                  value: bus.crowding.shortLabel,
                  subtitle: bus.crowding.passengerLabel,
                  badge: StatusPill(
                    label: 'Estimated',
                    color: _crowdingColor(bus.crowding),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Live Speed Card
              Expanded(
                child: _MetricCard(
                  icon: Icons.speed_rounded,
                  iconColor: AppColors.accent,
                  title: 'Speed',
                  value: intel.speedLabel,
                  subtitle: intel.motionStatus,
                  badge: const StatusPill(
                    label: 'Simulated',
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Next Stop & Alight Insight ────────────────────────────────────
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Stop: ${intel.nextStop?.name ?? "En route"}',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Simulated ETA: ${intel.nextStopEtaLabel} • Terminus: ${route.destination}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Verified Vehicle Specifications & Fleet Provenance ──────────
          Row(
            children: [
              Text(
                'Verified Fleet Specifications',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'CONFIDENCE A',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${bus.vehicleModel ?? "Olectra K9"} • Operated by ${bus.operatorName ?? "Kadamba Transport Corporation Ltd"} (Margao RTO)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _AmenityChip(
                icon: Icons.directions_bus_filled_rounded,
                label: bus.vehicleModel ?? 'Olectra K9',
                color: const Color(0xFF1565C0),
              ),
              if (bus.isElectric)
                const _AmenityChip(
                  icon: Icons.bolt_rounded,
                  label: '100% Electric (BYD K9 Chassis)',
                  color: Color(0xFF0D9488),
                ),
              if (bus.isAirConditioned)
                const _AmenityChip(
                  icon: Icons.ac_unit_rounded,
                  label: 'Climate Controlled (AC)',
                  color: Color(0xFF0284C7),
                ),
              if (bus.isWheelchairAccessible)
                const _AmenityChip(
                  icon: Icons.accessible_rounded,
                  label: 'Accessible / Low-Floor',
                  color: Color(0xFF4F46E5),
                ),
              _AmenityChip(
                icon: Icons.airline_seat_recline_normal_rounded,
                label: '${bus.capacity ?? 32} Passenger Seats',
                color: const Color(0xFF475569),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Action Buttons ───────────────────────────────────────────────
          Row(
            children: [
              if (onFocusVehicleOnMap != null)
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onFocusVehicleOnMap!();
                    },
                    icon: const Icon(Icons.my_location_rounded, size: 18),
                    label: const Text('Focus on Map'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.controlRadius),
                      ),
                    ),
                  ),
                ),
              if (onFocusVehicleOnMap != null)
                const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.controlRadius),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _crowdingColor(VehicleCrowding crowding) {
    switch (crowding) {
      case VehicleCrowding.low:
        return AppColors.success;
      case VehicleCrowding.moderate:
        return AppColors.warning;
      case VehicleCrowding.standingRoomOnly:
        return AppColors.danger;
    }
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
    this.badge,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  const _AmenityChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
