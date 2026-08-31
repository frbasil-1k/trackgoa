import 'package:flutter/material.dart';

/// Premium Google Maps-style bus marker for Phase 6 integration.
///
/// Displays live bus position with direction indicator and route color.
class BusMarkerWidget extends StatelessWidget {
  const BusMarkerWidget({
    required this.routeColor,
    required this.headingDegrees,
    this.isSelected = false,
    super.key,
  });

  final Color routeColor;
  final double headingDegrees;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: headingDegrees * (3.14159 / 180),
      child: Container(
        width: isSelected ? 44 : 36,
        height: isSelected ? 44 : 36,
        decoration: BoxDecoration(
          color: routeColor,
          borderRadius: BorderRadius.circular(isSelected ? 14 : 12),
          border: Border.all(
            color: Colors.white,
            width: isSelected ? 3 : 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: routeColor.withValues(alpha: 0.4),
              blurRadius: isSelected ? 16 : 12,
              spreadRadius: isSelected ? 2 : 1,
            ),
          ],
        ),
        child: Icon(
          Icons.directions_bus_rounded,
          color: Colors.white,
          size: isSelected ? 22 : 18,
        ),
      ),
    );
  }
}
