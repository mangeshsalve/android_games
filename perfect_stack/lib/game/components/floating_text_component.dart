import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// Short-lived label (e.g. "PERFECT") that drifts up and fades out.
class FloatingTextComponent extends PositionComponent {
  FloatingTextComponent({required String text, required Vector2 position})
    : _painter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            shadows: [Shadow(color: Color(0x66000000), blurRadius: 6)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(),
      super(position: position, anchor: Anchor.center, priority: 10) {
    size = Vector2(_painter.width, _painter.height);
  }

  static const double duration = 0.8;
  static const double rise = 36;

  final TextPainter _painter;
  final Paint _layerPaint = Paint();
  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    position.y -= rise / duration * dt;
    if (_elapsed >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / duration).clamp(0.0, 1.0);
    final opacity = t < 0.6 ? 1.0 : 1 - (t - 0.6) / 0.4;
    _layerPaint.color = Color.fromRGBO(0, 0, 0, opacity);
    canvas.saveLayer(null, _layerPaint);
    _painter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  void onRemove() {
    _painter.dispose();
    super.onRemove();
  }
}
