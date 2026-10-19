import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_stack/game/systems/stack_logic.dart';
import 'package:perfect_stack/models/stack_block.dart';

void main() {
  const top = StackBlock(left: 100, width: 200);

  PlacementResult drop(double left, {double width = 200}) => StackLogic.resolve(
    top: top,
    dropped: StackBlock(left: left, width: width),
    perfectTolerance: 5,
  );

  test('drop within tolerance is perfect and snaps to the block below', () {
    final result = drop(104);
    expect(result.outcome, PlacementOutcome.perfect);
    expect(result.placed, top);
    expect(result.debris, isNull);
  });

  test('overhang on the right is trimmed', () {
    final result = drop(150);
    expect(result.outcome, PlacementOutcome.trimmed);
    expect(result.placed, const StackBlock(left: 150, width: 150));
    expect(result.debris, const StackBlock(left: 300, width: 50));
  });

  test('overhang on the left is trimmed', () {
    final result = drop(40);
    expect(result.outcome, PlacementOutcome.trimmed);
    expect(result.placed, const StackBlock(left: 100, width: 140));
    expect(result.debris, const StackBlock(left: 40, width: 60));
  });

  test('no overlap is a miss', () {
    expect(drop(300).isMiss, isTrue);
    expect(drop(-100).isMiss, isTrue);
    expect(drop(-200).isMiss, isTrue);
  });

  test('a sliver thinner than the minimum width is a miss', () {
    expect(drop(299.5).isMiss, isTrue);
  });

  test('grow widens around the centre and respects the maximum', () {
    const block = StackBlock(left: 100, width: 100);
    expect(
      StackLogic.grow(block, 10, 240),
      const StackBlock(left: 95, width: 110),
    );
    expect(StackLogic.grow(block, 10, 100), block);
    expect(StackLogic.grow(block, 500, 240).width, 240);
  });
}
