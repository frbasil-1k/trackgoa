import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class TrackGoaApp extends StatelessWidget {
  const TrackGoaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'TrackGoa',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    routerConfig: appRouter,
  );
}
