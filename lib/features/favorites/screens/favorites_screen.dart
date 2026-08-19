import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: const SafeArea(
        top: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Text('Saved routes will appear here.'),
          ),
        ),
      ),
    );
  }
}
