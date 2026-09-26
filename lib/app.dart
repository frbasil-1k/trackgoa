import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/repository_providers.dart';

class SmartGoApp extends ConsumerStatefulWidget {
  const SmartGoApp({super.key});

  @override
  ConsumerState<SmartGoApp> createState() => _SmartGoAppState();
}

class _SmartGoAppState extends ConsumerState<SmartGoApp> {
  /// Tracks the previous theme mode to detect when it changes.
  ThemeMode? _previousThemeMode;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(flutterThemeModeProvider);

    // Force the MaterialApp.router and its GoRouter to rebuild when the
    // theme mode changes. Without this, GoRouter's internal state caches the
    // old theme context and Home/Favorites screens never update.
    final needsRouterRebuild = _previousThemeMode != themeMode;
    if (needsRouterRebuild) {
      _previousThemeMode = themeMode;
    }

    return MaterialApp.router(
      key: needsRouterRebuild ? ValueKey(themeMode) : null,
      title: 'SMART-GO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
