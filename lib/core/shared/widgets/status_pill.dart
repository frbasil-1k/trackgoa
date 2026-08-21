import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Small status treatment for bus and service summaries.
class StatusPill extends StatelessWidget {
  const StatusPill({required this.label, required this.color, super.key});

  factory StatusPill.running() =>
      const StatusPill(label: 'Running', color: AppColors.success);
  factory StatusPill.delayed() =>
      const StatusPill(label: 'Delayed', color: AppColors.warning);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
    ),
  );
}
