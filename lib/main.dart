import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/repositories/repository_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Phase 6.5+ — SharedPreferences instance used by both Favorites and
        // Settings repositories. Swap this for a real persistence layer later.
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const TrackGoaApp(),
    ),
  );
}
