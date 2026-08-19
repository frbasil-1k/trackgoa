import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_spacing.dart';

class RouteListScreen extends StatelessWidget {
  const RouteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routes')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(AppSpacing.md),
              leading: const CircleAvatar(child: Text('R1')),
              title: const Text('Sample Route'),
              subtitle: const Text('Placeholder route for navigation testing'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RoutePaths.trackingFor('r1')),
            ),
          ),
        ),
      ),
    );
  }
}
