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
          _buildAnimatedControl(
            delay: 0,
            child: _GlassButton(
              icon: Icons.add_rounded,
              onPressed: () {
                final currentZoom = mapController.camera.zoom;
                mapController.move(
                  mapController.camera.center,
                  (currentZoom + 1).clamp(10.0, 18.0),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildAnimatedControl(
            delay: 40,
            child: _GlassButton(
              icon: Icons.remove_rounded,
              onPressed: () {
                final currentZoom = mapController.camera.zoom;
                mapController.move(
                  mapController.camera.center,
                  (currentZoom - 1).clamp(10.0, 18.0),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildAnimatedControl(
            delay: 80,
            child: _GlassButton(
              icon: Icons.my_location_rounded,
              onPressed: onCenterRoute,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedControl({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 180 + delay),
      curve: Curves.easeOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: child,
        ),
      ),
      child: child,
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
          boxShadow: [
            // Soft primary shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            // Subtle depth shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
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
