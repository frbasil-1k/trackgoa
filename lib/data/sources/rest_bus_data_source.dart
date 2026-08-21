import '../models/bus_position.dart';
import 'bus_data_source.dart';

/// Future REST polling implementation placeholder. No network work occurs yet.
class RestBusDataSource implements BusDataSource {
  const RestBusDataSource();

  @override
  Stream<List<BusPosition>> watchBusPositions(String routeId) => Stream.empty();
}
