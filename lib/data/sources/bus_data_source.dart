import '../models/bus_position.dart';

/// Stream contract for live bus positions, swappable for simulated, REST, or
/// WebSocket implementations without changing repository or UI code.
abstract interface class BusDataSource {
  Stream<List<BusPosition>> watchBusPositions(String routeId);
}
