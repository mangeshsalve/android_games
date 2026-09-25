import 'dart:math' as math;

import '../../models/stack_block.dart';

enum PlacementOutcome { perfect, trimmed, miss }

class PlacementResult {
  const PlacementResult._(this.outcome, this.placed, this.debris);

  const PlacementResult.miss() : this._(PlacementOutcome.miss, null, null);

  final PlacementOutcome outcome;

  /// The part of the dropped block that stays on the stack.
  final StackBlock? placed;

  /// The part that was cut off and falls away (null for perfect or miss).
  final StackBlock? debris;

  bool get isMiss => outcome == PlacementOutcome.miss;
  bool get isPerfect => outcome == PlacementOutcome.perfect;
}

/// Pure placement rules, kept free of Flame so they are easy to unit test.
class StackLogic {
  const StackLogic._();

  /// Slivers thinner than this count as a miss; they would be unplayable.
  static const double minimumWidth = 1.0;

  static PlacementResult resolve({
    required StackBlock top,
    required StackBlock dropped,
    required double perfectTolerance,
  }) {
    if ((dropped.left - top.left).abs() <= perfectTolerance) {
      return PlacementResult._(
        PlacementOutcome.perfect,
        StackBlock(left: top.left, width: math.min(dropped.width, top.width)),
        null,
      );
    }

    final overlapLeft = math.max(top.left, dropped.left);
    final overlapRight = math.min(top.right, dropped.right);
    final overlap = overlapRight - overlapLeft;
    if (overlap < minimumWidth) {
      return const PlacementResult.miss();
    }

    final debris = dropped.left < top.left
        ? StackBlock(left: dropped.left, width: top.left - dropped.left)
        : StackBlock(left: top.right, width: dropped.right - top.right);

    return PlacementResult._(
      PlacementOutcome.trimmed,
      StackBlock(left: overlapLeft, width: overlap),
      debris,
    );
  }

  /// Rewards a streak of perfect drops by widening the block around its
  /// centre, never beyond [maxWidth].
  static StackBlock grow(StackBlock block, double amount, double maxWidth) {
    final newWidth = math.min(block.width + amount, maxWidth);
    if (newWidth <= block.width) return block;
    return StackBlock(left: block.center - newWidth / 2, width: newWidth);
  }
}
