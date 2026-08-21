import '../models/stop_model.dart';
import 'mock_routes.dart';

/// Flattened stop fixture for consumers that need to search all Goa stops.
final mockStops = List<StopModel>.unmodifiable(
  mockRoutes.expand((route) => route.stops),
);
