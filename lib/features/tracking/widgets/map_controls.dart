import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../core/theme/app_spacing.dart';

/// Premium glass-style floating map controls inspired by Google Maps.
class MapControls extends StatelessWidget {
  const MapControls({
    required this.mapController,
    required this.onCenterRoute,
    super.key,
  });

  final MapController mapController;
  final VoidCallback onCenterRoute;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + AppSpacing.md,
      right: AppSpacing.md,
      child: Column(
        children: [
          // Removed TweenAnimationBuilder animations - controls appear instantly
          // This reduces animation overhead on screen load
          _GlassButton(
            icon: Icons.add_rounded,
            onPressed: () {
              final currentZoom = mapController.camera.zoom;
              mapController.move(
                mapController.camera.center,
                (currentZoom + 1).clamp(10.0, 18.0),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          _GlassButton(
            icon: Icons.remove_rounded,
            onPressed: () {
              final currentZoom = mapController.camera.zoom;
              mapController.move(
                mapController.camera.center,
                (currentZoom - 1).clamp(10.0, 18.0),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _GlassButton(
            icon: Icons.my_location_rounded,
            onPressed: onCenterRoute,
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatefulWidget {
  const _GlassButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          shape: BoxShape.circle,
          boxShadow: const [
            // Single shadow for better performance
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            customBorder: const CircleBorder(),
            splashColor: Colors.black.withValues(alpha: 0.05),
            highlightColor: Colors.black.withValues(alpha: 0.03),
            child: Center(
              child: Icon(
                widget.icon,
                size: 24,
                color: const Color(0xFF16292D),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
