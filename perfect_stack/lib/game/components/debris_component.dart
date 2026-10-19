import 'package:flame/components.dart';

import '../../models/block_palette.dart';
import 'block_component.dart';

/// A cut-off piece that tumbles away and removes itself once off screen.
class DebrisComponent extends BlockComponent {
  DebrisComponent({
    required Vector2 center,
    required super.size,
    required super.hue,
    required super.palette,
    required this.horizontalVelocity,
    required this.angularVelocity,
    required this.removeBelowY,
  }) : super(position: center, anchor: Anchor.center, priority: -1);

  static const double gravity = 1400;

  final double horizontalVelocity;
  final double angularVelocity;
  final double removeBelowY;
  double _verticalVelocity = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _verticalVelocity += gravity * dt;
    position.x += horizontalVelocity * dt;
    position.y += _verticalVelocity * dt;
    angle += angularVelocity * dt;
    if (position.y > removeBelowY) {
      removeFromParent();
    }
  }

  static DebrisComponent fromBlock({
    required double left,
    required double top,
    required double width,
    required double height,
    required double hue,
    required BlockPalette palette,
    required double direction,
    required double removeBelowY,
  }) {
    return DebrisComponent(
      center: Vector2(left + width / 2, top + height / 2),
      size: Vector2(width, height),
      hue: hue,
      palette: palette,
      horizontalVelocity: direction * 60,
      angularVelocity: direction * 2.2,
      removeBelowY: removeBelowY,
    );
  }
}
