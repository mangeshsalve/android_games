import 'dart:math' as math;

/// Tunable difficulty curve. Add named constructors for future
/// difficulty modes (e.g. easy / hard) without touching the game code.
class DifficultyConfig {
  const DifficultyConfig({
    this.baseSpeed = 170,
    this.speedPerLevel = 7,
    this.maxSpeed = 470,
    this.basePerfectTolerance = 7,
    this.minPerfectTolerance = 4,
    this.tolerancePerLevel = 0.06,
    this.perfectStreakForGrowth = 3,
    this.growthPerPerfect = 8,
  });

  const DifficultyConfig.normal() : this();

  /// Horizontal block speed in world units per second.
  final double baseSpeed;
  final double speedPerLevel;
  final double maxSpeed;

  /// How far (world units) a drop may be off and still count as perfect.
  final double basePerfectTolerance;
  final double minPerfectTolerance;
  final double tolerancePerLevel;

  /// Consecutive perfect drops needed before the block starts growing back.
  final int perfectStreakForGrowth;
  final double growthPerPerfect;

  double speedFor(int level) =>
      math.min(baseSpeed + level * speedPerLevel, maxSpeed);

  double perfectToleranceFor(int level) => math.max(
    basePerfectTolerance - level * tolerancePerLevel,
    minPerfectTolerance,
  );
}
