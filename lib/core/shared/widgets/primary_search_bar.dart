import 'package:flutter/material.dart';

import 'app_card.dart';

/// A glass-style search affordance which can be wired to real search later.
class PrimarySearchBar extends StatelessWidget {
  const PrimarySearchBar({required this.hintText, super.key, this.onTap});

  final String hintText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    glass: true,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    onTap: onTap,
    child: Row(
      children: [
        const Icon(Icons.search_rounded),
        const SizedBox(width: 12),
        Expanded(
          child: Text(hintText, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const Icon(Icons.tune_rounded, size: 20),
      ],
    ),
  );
}
