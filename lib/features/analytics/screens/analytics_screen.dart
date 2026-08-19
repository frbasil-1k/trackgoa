import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({required this.routeId, super.key});
  final String routeId;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Analytics ${routeId.toUpperCase()}')),
    body: const SafeArea(
      top: false,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Text('Route analytics will be available in a later phase.'),
        ),
      ),
    ),
  );
}
