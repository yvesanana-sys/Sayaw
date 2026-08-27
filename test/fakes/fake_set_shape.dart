import 'package:sayaw/data/set_ordering.dart';
import 'package:sayaw/ui/state/library_access.dart';

/// The set shape without a database or an engine behind it.
class FakeSetShape implements SetShapeAccess {
  FakeSetShape({
    this.openPlaylistId = 'set',
    SetShape? shape,
    this.isRunning = false,
    this.appliesInFull = true,
  }) : shape = shape ?? const SetShape();

  @override
  final String? openPlaylistId;

  @override
  bool isRunning;

  /// What [writeSetShape] reports back — false stands for a running set that
  /// could only take half of it.
  bool appliesInFull;

  SetShape shape;

  /// Everything written, in order.
  final List<SetShape> writes = [];

  /// What [orderSetByTempo] hands back, and every order it was asked for.
  OrderedSet ordered =
      const OrderedSet(itemIds: [], guessed: [], withoutTempo: []);
  final List<TempoOrder> orderings = [];

  @override
  Future<OrderedSet> orderSetByTempo(TempoOrder order) async {
    orderings.add(order);
    return ordered;
  }

  @override
  Future<SetShape> readSetShape() async => shape;

  @override
  Future<bool> writeSetShape(SetShape next) async {
    writes.add(next);
    shape = next;
    return appliesInFull;
  }
}
