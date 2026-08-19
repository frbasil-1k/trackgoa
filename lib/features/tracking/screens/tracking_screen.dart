import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_spacing.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({required this.routeId, super.key});

  final String routeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tracking ${routeId.toUpperCase()}')),
      body: SafeArea(
        top: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.map_outlined, size: 48),
                const SizedBox(height: AppSpacing.sm),
                const Text('Route tracking is being prepared.'),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  onPressed: () =>
                      context.push(RoutePaths.analyticsFor(routeId)),
                  child: const Text('View route analytics'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
