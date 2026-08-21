import '../models/bus_position.dart';
import 'bus_data_source.dart';

/// Future WebSocket implementation placeholder. No socket is opened yet.
class WebSocketBusDataSource implements BusDataSource {
  const WebSocketBusDataSource();

  @override
  Stream<List<BusPosition>> watchBusPositions(String routeId) => Stream.empty();
}
