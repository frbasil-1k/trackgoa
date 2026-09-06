import 'package:flutter/material.dart';

import '../../../data/models/route_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'app_card.dart';
import 'favorite_icon_button.dart';
import 'live_badge.dart';

/// Data-driven route summary used on Home and future route listings.
class RouteCard extends StatelessWidget {
  const RouteCard({
    required this.route,
    required this.reliabilityPercent,
    required this.onTap,
    this.showFavorite = true,
    super.key,
  });

  final RouteModel route;
  final int reliabilityPercent;
  final VoidCallback onTap;
  final bool showFavorite;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Row(
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
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: route.color),
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
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const LiveBadge(),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '~${route.estimatedTravelMinutes} min  •  $reliabilityPercent% reliable',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (showFavorite) ...[
          const SizedBox(width: AppSpacing.xs),
          FavoriteIconButton(routeId: route.id, size: 36, iconSize: 18),
        ] else
          const SizedBox(width: AppSpacing.sm),
        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
      ],
    ),
  );
}
