import 'package:flutter/material.dart';

/// Premium Google Maps-style stop marker with transit styling.
///
/// Displays stop position with order number and selection state.
class StopMarkerWidget extends StatelessWidget {
  const StopMarkerWidget({
    required this.stopNumber,
    required this.routeColor,
    this.isFirst = false,
    this.isLast = false,
    this.isSelected = false,
    super.key,
  });

  final int stopNumber;
  final Color routeColor;
  final bool isFirst;
  final bool isLast;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final size = isSelected ? 36.0 : 32.0;
    final iconSize = isSelected ? 18.0 : 16.0;

    // Origin marker - filled circle with route color and subtle glow
    if (isFirst) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: routeColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 3.5,
          ),
          boxShadow: [
            // Soft outer shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
            // Route color glow
            BoxShadow(
              color: routeColor.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.circle,
            color: Colors.white,
            size: iconSize * 0.5,
          ),
        ),
      );
    }

    // Destination marker - location pin with route color and depth
    if (isLast) {
      return Container(
        width: size + 4,
        height: size + 4,
        decoration: BoxDecoration(
          color: Colors.transparent,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: routeColor.withValues(alpha: 0.25),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.location_on,
              color: routeColor,
              size: size + 4,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            Positioned(
              top: (size + 4) * 0.22,
              child: Container(
                width: (size + 4) * 0.35,
                height: (size + 4) * 0.35,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Intermediate stops - white circle with number and soft depth
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: routeColor,
          width: isSelected ? 3.0 : 2.5,
        ),
        boxShadow: [
          // Soft outer shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
          // Subtle inner depth
          BoxShadow(
            color: routeColor.withValues(alpha: 0.08),
            blurRadius: 4,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$stopNumber',
          style: TextStyle(
            color: routeColor,
            fontSize: iconSize - 2,
            fontWeight: FontWeight.w700,
            height: 1,
            shadows: [
              Shadow(
                color: routeColor.withValues(alpha: 0.1),
                blurRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
