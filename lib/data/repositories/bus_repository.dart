import '../models/bus_position.dart';
import '../sources/bus_data_source.dart';

/// Bus position access boundary that remains agnostic to the transport source.
class BusRepository {
  const BusRepository(this._dataSource);

  final BusDataSource _dataSource;

  Stream<List<BusPosition>> watchBusPositions(String routeId) =>
      _dataSource.watchBusPositions(routeId);
}
