import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/journey_leg.dart';
import '../models/journey_location.dart';
import '../models/journey_option.dart';

/// Rich visual card presenting a journey option with summary metrics, transit badges,
/// and step-by-step vertical itinerary.
class JourneyOptionCard extends StatelessWidget {
  const JourneyOptionCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onSelect,
    required this.onStartJourney,
  });

  final JourneyOption option;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onStartJourney;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    // Category badge colors adapt to theme
    final badgeBg = option.isDirect
        ? colorScheme.tertiary.withValues(alpha: isDark ? 0.20 : 0.12)
        : colorScheme.primary.withValues(alpha: isDark ? 0.20 : 0.12);
    final badgeFg = option.isDirect ? colorScheme.tertiary : colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: isSelected ? 16 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        splashColor: colorScheme.primary.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Category Badge + Total Duration + Fare
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      option.categoryLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: badgeFg,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${option.totalDurationMinutes} min',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Timings and Walking info
              Row(
                children: [
                  Text(
                    '${option.departureTime} – ${option.arrivalTime}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('•', style: TextStyle(color: colorScheme.outlineVariant)),
                  const SizedBox(width: 8),
                  Icon(Icons.directions_walk_rounded, size: 15, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${option.walkingMinutes} min walk',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (option.hasLiveVehicle) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              // Destination & Alighting Access Distinction Banner
              if (option.alightingStop != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.tertiary.withValues(alpha: isDark ? 0.35 : 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 14, color: colorScheme.error),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'TO: ${option.destination.name}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.directions_bus_rounded, size: 13, color: colorScheme.tertiary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Alight at: ${option.alightingStop!.name}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.tertiary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (option.finalWalkingLeg != null) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.directions_walk_rounded, size: 13, color: colorScheme.tertiary),
                            const SizedBox(width: 2),
                            Text(
                              '${option.finalWalkingLeg!.distanceMeters.round()}m walk (${option.finalWalkingLeg!.durationMinutes} min)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.tertiary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),

              // Legs Route Pills Bar
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: _buildRoutePills(context),
              ),

              // If Selected: Show Vertical Timeline & Action Button
              if (isSelected) ...[
                const SizedBox(height: AppSpacing.md),
                Divider(height: 1, color: colorScheme.outlineVariant),
                const SizedBox(height: AppSpacing.md),

                _VerticalJourneyTimeline(
                  legs: option.legs,
                  destination: option.destination,
                ),

                const SizedBox(height: AppSpacing.md),
                // Epistemic provenance notice
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified_user_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          option.epistemicStatus,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Start Journey Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onStartJourney,
                    icon: const Icon(Icons.navigation_rounded),
                    label: const Text(
                      'Start Live Journey',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRoutePills(BuildContext context) {
    final widgets = <Widget>[];
    final colorScheme = Theme.of(context).colorScheme;

    for (int i = 0; i < option.legs.length; i++) {
      final leg = option.legs[i];
      if (leg.isWalking) {
        widgets.add(
          Icon(Icons.directions_walk_rounded, size: 18, color: colorScheme.onSurfaceVariant),
        );
      } else {
        final routeColor = leg.route?.color ?? AppColors.primary;
        widgets.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: routeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: routeColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_bus_rounded, size: 14, color: routeColor),
                const SizedBox(width: 4),
                Text(
                  leg.route?.shortName ?? 'Bus',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: routeColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (i < option.legs.length - 1) {
        widgets.add(
          Icon(Icons.arrow_forward_ios_rounded, size: 11, color: colorScheme.outlineVariant),
        );
      }
    }

    return widgets;
  }
}

/// Detailed step-by-step vertical timeline showing every stage of the journey.
class _VerticalJourneyTimeline extends StatelessWidget {
  const _VerticalJourneyTimeline({
    required this.legs,
    required this.destination,
  });

  final List<JourneyLeg> legs;
  final JourneyLocation destination;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(legs.length, (index) {
          final leg = legs[index];
          final nodeColor = leg.isTransit
              ? (leg.route?.color ?? colorScheme.primary)
              : (leg.legType == JourneyLegType.transferWalk
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant);

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and connector line
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: nodeColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          leg.isTransit
                              ? Icons.directions_bus_rounded
                              : (leg.legType == JourneyLegType.transferWalk
                                  ? Icons.sync_alt_rounded
                                  : Icons.directions_walk_rounded),
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2.5,
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),

                // Content Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leg.instructions,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${leg.fromName} → ${leg.toName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (leg.liveVehicleCountdown != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.sensors_rounded, size: 13, color: colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                leg.liveVehicleCountdown!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        // Final Destination Marker Node
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Destination: ${destination.name}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (destination.address != null || destination.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          destination.address ?? destination.subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
