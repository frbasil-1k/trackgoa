import 'package:flutter/material.dart';

import '../../../core/shared/widgets/live_badge.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/route_model.dart';

/// Floating glassmorphic route info card displayed at the top of the tracking screen.
///
/// Shows route badge, name, frequency, and live status in a compact card
/// inspired by Google Maps and Uber design patterns.
class RouteInfoCard extends StatelessWidget {
  const RouteInfoCard({
    required this.route,
    super.key,
  });

  final RouteModel route;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, -20 * (1 - value)),
          child: child,
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Route Badge
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: route.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                    border: Border.all(
                      color: route.color.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    route.shortName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: route.color,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),

                // Vertical Divider
                Container(
                  width: 1,
                  height: 32,
                  color: Colors.black.withValues(alpha: 0.08),
                ),

                const SizedBox(width: AppSpacing.sm),

                // Route Info Column
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${route.origin} → ${route.destination}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Every 15 min',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppSpacing.xs),

                // Live Badge
                const LiveBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
