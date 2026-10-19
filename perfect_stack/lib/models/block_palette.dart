import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Colour scheme for blocks and the background.
///
/// Hues are kept unbounded (not wrapped to 0..360) so they can be smoothly
/// interpolated; they are wrapped only when converted to a [Color].
/// New skins/themes can be added as additional palettes.
class BlockPalette {
  const BlockPalette({
    this.hueStep = 9,
    this.blockSaturation = 0.68,
    this.blockLightness = 0.60,
    this.backgroundHueMin = 205,
    this.backgroundHueMax = 295,
  });

  static const BlockPalette classic = BlockPalette();

  final double hueStep;
  final double blockSaturation;
  final double blockLightness;
  final double backgroundHueMin;
  final double backgroundHueMax;

  double hueForRow(double startHue, int row) => startHue + row * hueStep;

  Color blockColor(double hue) => HSLColor.fromAHSL(
    1,
    _wrap(hue),
    blockSaturation,
    blockLightness,
  ).toColor();

  Color blockHighlight(double hue) => HSLColor.fromAHSL(
    1,
    _wrap(hue),
    blockSaturation,
    (blockLightness + 0.14).clamp(0.0, 1.0),
  ).toColor();

  Color blockShade(double hue) => HSLColor.fromAHSL(
    1,
    _wrap(hue),
    blockSaturation,
    (blockLightness - 0.16).clamp(0.0, 1.0),
  ).toColor();

  /// Background hues stay in a calm blue-to-purple band (never muddy
  /// browns) while still drifting as the tower grows.
  Color backgroundTop(double hue) =>
      HSLColor.fromAHSL(1, _backgroundHue(hue), 0.45, 0.30).toColor();

  Color backgroundBottom(double hue) => HSLColor.fromAHSL(
    1,
    _wrap(_backgroundHue(hue) + 25),
    0.50,
    0.11,
  ).toColor();

  double _backgroundHue(double hue) =>
      backgroundHueMin +
      (backgroundHueMax - backgroundHueMin) *
          (0.5 + 0.5 * math.sin(hue * math.pi / 180));

  static double _wrap(double hue) => hue % 360;
}
