import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_stack/game/systems/difficulty.dart';
import 'package:perfect_stack/services/ad_service.dart';

void main() {
  group('DifficultyConfig', () {
    const config = DifficultyConfig.normal();

    test('speed increases with level and is capped', () {
      expect(config.speedFor(10), greaterThan(config.speedFor(0)));
      expect(config.speedFor(10000), config.maxSpeed);
    });

    test('perfect tolerance shrinks but never below the minimum', () {
      expect(
        config.perfectToleranceFor(20),
        lessThan(config.perfectToleranceFor(0)),
      );
      expect(config.perfectToleranceFor(10000), config.minPerfectTolerance);
    });
  });

  group('InterstitialPolicy', () {
    test('waits for enough games and respects the minimum interval', () {
      var now = DateTime(2026);
      final policy = InterstitialPolicy(
        gamesBetweenAds: 3,
        minInterval: const Duration(seconds: 90),
        clock: () => now,
      );

      policy.recordGameFinished();
      policy.recordGameFinished();
      expect(policy.shouldShow, isFalse);
      policy.recordGameFinished();
      expect(policy.shouldShow, isTrue);
      policy.recordShown();

      for (var i = 0; i < 3; i++) {
        policy.recordGameFinished();
      }
      now = now.add(const Duration(seconds: 30));
      expect(policy.shouldShow, isFalse, reason: 'too soon after last ad');
      now = now.add(const Duration(seconds: 60));
      expect(policy.shouldShow, isTrue);
    });
  });
}
