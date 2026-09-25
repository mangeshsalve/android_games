import 'dart:ui';

import 'package:flame/components.dart';

import '../../models/block_palette.dart';

/// Full-screen vertical gradient that slowly shifts hue with the stack.
/// Lives in the camera backdrop, so it is drawn in screen coordinates.
class BackgroundComponent extends Component with HasGameReference {
  BackgroundComponent({required this.palette, required double hue})
    : _hue = hue,
      _targetHue = hue;

  final BlockPalette palette;
  final Paint _paint = Paint();
  double _hue;
  double _targetHue;
  double? _shaderHue;
  Vector2? _shaderSize;

  set targetHue(double value) => _targetHue = value;

  void snapTo(double hue) {
    _hue = hue;
    _targetHue = hue;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _hue += (_targetHue - _hue) * (dt * 2).clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    final size = game.canvasSize;
    if (size.x <= 0 || size.y <= 0) return;
    final shaderHue = _shaderHue;
    if (shaderHue == null ||
        (shaderHue - _hue).abs() > 0.05 ||
        _shaderSize != size) {
      _paint.shader = Gradient.linear(Offset.zero, Offset(0, size.y), [
        palette.backgroundTop(_hue),
        palette.backgroundBottom(_hue),
      ]);
      _shaderHue = _hue;
      _shaderSize = size.clone();
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _paint);
  }
}
