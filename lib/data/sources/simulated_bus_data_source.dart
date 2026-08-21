import '../models/bus_position.dart';
import 'bus_data_source.dart';

/// Stream-shaped source reserved for Phase 6's movement simulation.
///
/// It deliberately has no timer or movement logic in Phase 2; subscribers get
/// one empty snapshot so later consumers can adopt the final stream contract.
class SimulatedBusDataSource implements BusDataSource {
  const SimulatedBusDataSource();

  @override
  Stream<List<BusPosition>> watchBusPositions(String routeId) =>
      Stream.value(const <BusPosition>[]);
}
