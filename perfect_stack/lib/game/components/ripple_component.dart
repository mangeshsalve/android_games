import 'dart:ui';

import 'package:flame/components.dart';

/// An expanding, fading outline around a block after a perfect drop.
class RippleComponent extends PositionComponent {
  RippleComponent({required Rect rect}) : _rect = rect, super(priority: 5);

  static const double duration = 0.45;
  static const double maxSpread = 16;

  final Rect _rect;
  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / duration).clamp(0.0, 1.0);
    final eased = 1 - (1 - t) * (1 - t);
    final spread = maxSpread * eased;
    _paint.color = Color.fromRGBO(255, 255, 255, (1 - t) * 0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        _rect.inflate(spread),
        Radius.circular(4 + spread / 2),
      ),
      _paint,
    );
  }
}
