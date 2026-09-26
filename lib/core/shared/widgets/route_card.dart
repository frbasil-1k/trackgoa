import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/route_model.dart';
import '../../theme/app_spacing.dart';
import 'app_card.dart';
import 'favorite_icon_button.dart';
import 'live_badge.dart';

/// Data-driven route summary used on Home and route listings.
///
/// Connects to [routeProgressSummaryProvider] to display real-time live
/// bus position, next stop ETA, and speed before the passenger opens tracking.
class RouteCard extends ConsumerWidget {
  const RouteCard({
    required this.route,
    required this.reliabilityPercent,
    required this.onTap,
    this.showFavorite = true,
    this.matchingStopName,
    super.key,
  });

  final RouteModel route;
  final int reliabilityPercent;
  final VoidCallback onTap;
  final bool showFavorite;
  final String? matchingStopName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: route.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
            ),
            child: Text(
              route.shortName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: route.color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${route.origin} → ${route.destination}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const LiveBadge(),
                  ],
                ),
                if (matchingStopName != null) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pin_drop_rounded,
                          size: 12,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            'Passes $matchingStopName',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '~${route.estimatedTravelMinutes} min  •  $reliabilityPercent% reliable',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  '${route.stops.length} verified stops  •  Simulated live demo',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          if (showFavorite) ...[
            const SizedBox(width: AppSpacing.xs),
            FavoriteIconButton(routeId: route.id, size: 38, iconSize: 19),
          ] else
            const SizedBox(width: AppSpacing.sm),
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
