import 'dart:async';

import 'package:flutter/foundation.dart';

/// Abstraction over the ad network so the game never depends on a
/// specific SDK. Replace [MockAdService] with an AdMob implementation
/// later (see README) without touching any screen or game code.
abstract class AdService {
  Future<void> initialize();

  bool get isRewardedAdReady;

  /// Shows a rewarded ad. Completes with true only when the user earned
  /// the reward (watched the ad to the end).
  Future<bool> showRewardedAd();

  /// Shows an interstitial ad if one is loaded. Completes when the ad is
  /// dismissed (or immediately if none was available).
  Future<void> showInterstitialAd();

  void dispose();
}

/// Simulates ads so the full monetisation flow can be tested offline.
class MockAdService implements AdService {
  MockAdService({this.adDuration = const Duration(milliseconds: 1200)});

  final Duration adDuration;

  @override
  Future<void> initialize() async {}

  @override
  bool get isRewardedAdReady => true;

  @override
  Future<bool> showRewardedAd() async {
    debugPrint('MockAdService: showing rewarded ad');
    await Future<void>.delayed(adDuration);
    return true;
  }

  @override
  Future<void> showInterstitialAd() async {
    debugPrint('MockAdService: showing interstitial ad');
    await Future<void>.delayed(adDuration);
  }

  @override
  void dispose() {}
}

/// Use this to ship a build with no ads at all (e.g. "Remove Ads" bought).
class DisabledAdService implements AdService {
  @override
  Future<void> initialize() async {}

  @override
  bool get isRewardedAdReady => false;

  @override
  Future<bool> showRewardedAd() async => false;

  @override
  Future<void> showInterstitialAd() async {}

  @override
  void dispose() {}
}

/// Decides when an interstitial is appropriate: never on the first games,
/// then at most once every [gamesBetweenAds] finished games and never more
/// often than [minInterval].
class InterstitialPolicy {
  InterstitialPolicy({
    this.gamesBetweenAds = 3,
    this.minInterval = const Duration(seconds: 90),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final int gamesBetweenAds;
  final Duration minInterval;
  final DateTime Function() _clock;

  int _gamesSinceLastAd = 0;
  DateTime? _lastShownAt;

  void recordGameFinished() => _gamesSinceLastAd++;

  bool get shouldShow {
    if (_gamesSinceLastAd < gamesBetweenAds) return false;
    final last = _lastShownAt;
    return last == null || _clock().difference(last) >= minInterval;
  }

  void recordShown() {
    _gamesSinceLastAd = 0;
    _lastShownAt = _clock();
  }
}

/// The single entry point screens use for ads.
class AdManager {
  AdManager({required AdService service, InterstitialPolicy? policy})
    : _service = service,
      _policy = policy ?? InterstitialPolicy();

  final AdService _service;
  final InterstitialPolicy _policy;

  Future<void> initialize() async {
    try {
      await _service.initialize();
    } catch (error) {
      debugPrint('AdManager: initialisation failed ($error)');
    }
  }

  bool get canOfferContinue => _service.isRewardedAdReady;

  Future<bool> showRewardedForContinue() async {
    try {
      return await _service.showRewardedAd();
    } catch (error) {
      debugPrint('AdManager: rewarded ad failed ($error)');
      return false;
    }
  }

  /// Call when a run is fully over (player chose Retry or Home).
  Future<void> onRunFinished() async {
    _policy.recordGameFinished();
    if (!_policy.shouldShow) return;
    try {
      await _service.showInterstitialAd();
      _policy.recordShown();
    } catch (error) {
      debugPrint('AdManager: interstitial failed ($error)');
    }
  }

  void dispose() => _service.dispose();
}
