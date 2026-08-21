import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/route_model.dart';
import '../../../data/repositories/repository_providers.dart';

/// Home's read-only route feed, backed by the app-wide repository contract.
final homeRoutesProvider = FutureProvider<List<RouteModel>>(
  (ref) => ref.watch(routeRepositoryProvider).getRoutes(),
);
