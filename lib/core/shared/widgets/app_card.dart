import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// A softly elevated surface shared by SMART-GO feature screens.
///
/// Adapts to both light and dark themes using the active [ColorScheme].
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.glass = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    // Shadow is more subtle in dark mode (surfaces are already elevated by bg contrast)
    final shadowColor = isDark
        ? const Color(0xFF000000)
        : const Color(0xFF0B2C31);

    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: glass
            ? colorScheme.surface.withValues(alpha: 0.78)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: isDark ? 1.0 : 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: isDark ? 0.28 : 0.07),
            blurRadius: isDark ? 12 : 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        splashColor: colorScheme.primary.withValues(alpha: 0.06),
        highlightColor: colorScheme.primary.withValues(alpha: 0.04),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: glass
              ? BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: surface,
                )
              : surface,
        ),
      ),
    );
  }
}
