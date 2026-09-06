import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/repository_providers.dart';

/// Phase 6.5 — Animated favorite icon button.
///
/// Toggles the favorite state for the given [routeId] with a 250 ms
/// scale + rotation animation. Reads/writes [favoritesNotifierProvider]
/// for instant optimistic UI feedback.
class FavoriteIconButton extends ConsumerStatefulWidget {
  const FavoriteIconButton({
    required this.routeId,
    this.size = 40,
    this.iconSize = 22,
    super.key,
  });

  final String routeId;
  final double size;
  final double iconSize;

  @override
  ConsumerState<FavoriteIconButton> createState() =>
      _FavoriteIconButtonState();
}

class _FavoriteIconButtonState extends ConsumerState<FavoriteIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotateAnim = Tween<double>(begin: 0.0, end: 0.18).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onPressed() async {
    _controller.forward(from: 0);
    await ref.read(favoritesNotifierProvider.notifier)
        .toggleFavorite(widget.routeId);
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = ref.watch(isFavoriteProvider(widget.routeId));

    return ScaleTransition(
      scale: _scaleAnim,
      child: RotationTransition(
        turns: _rotateAnim,
        child: InkWell(
          onTap: _onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isFavorite
                  ? const Color(0xFFFFE5B4)
                  : Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              isFavorite
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: isFavorite
                  ? const Color(0xFFE65100)
                  : Colors.grey.shade600,
              size: widget.iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
