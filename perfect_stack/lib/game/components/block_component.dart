import 'dart:ui';

import 'package:flame/components.dart';

import '../../models/block_palette.dart';

/// A single coloured block drawn with a lighter top face and a darker
/// bottom edge for a subtle sense of depth.
class BlockComponent extends PositionComponent {
  BlockComponent({
    required Vector2 position,
    required Vector2 size,
    required double hue,
    required BlockPalette palette,
    this.faceHeight,
    super.anchor,
    super.priority,
  }) : super(position: position, size: size) {
    setHue(hue, palette);
  }

  static const double cornerRadius = 3;
  static const double highlightHeight = 5;
  static const double shadeHeight = 3;

  /// Height of the visible "front" of the block. Defaults to [size.y]; the
  /// foundation block uses a very tall body but a normal-looking top.
  final double? faceHeight;

  final Paint _body = Paint();
  final Paint _highlight = Paint();
  final Paint _shade = Paint();
  final Paint _pedestal = Paint();
  final Paint _flashPaint = Paint();
  double _flash = 0;

  void setHue(double hue, BlockPalette palette) {
    _body.color = palette.blockColor(hue);
    _highlight.color = palette.blockHighlight(hue);
    _shade.color = palette.blockShade(hue);
    _pedestal.color = palette.blockShade(hue).withValues(alpha: 0.35);
  }

  /// Briefly brightens the block; used as landing feedback.
  void flash() => _flash = 1;

  @override
  void update(double dt) {
    super.update(dt);
    if (_flash > 0) {
      _flash = (_flash - dt * 4).clamp(0.0, 1.0);
    }
  }

  @override
  void render(Canvas canvas) {
    final face = faceHeight ?? size.y;
    final rect = size.toRect();
    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(cornerRadius),
    );
    canvas.drawRRect(rrect, _body);

    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, highlightHeight), _highlight);
    if (face < size.y) {
      canvas.drawRect(Rect.fromLTWH(0, face, size.x, size.y - face), _pedestal);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, face - shadeHeight, size.x, shadeHeight),
      _shade,
    );
    if (_flash > 0) {
      _flashPaint.color = Color.fromRGBO(255, 255, 255, _flash * 0.55);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, face), _flashPaint);
    }
    canvas.restore();
  }
}
