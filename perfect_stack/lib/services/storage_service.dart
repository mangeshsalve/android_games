import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for scores and settings. Everything is cached in
/// memory after [create], so reads are synchronous.
class StorageService {
  StorageService._(this._prefs);

  static const _highScoreKey = 'high_score';
  static const _gamesPlayedKey = 'games_played';
  static const _soundEnabledKey = 'sound_enabled';
  static const _vibrationEnabledKey = 'vibration_enabled';

  final SharedPreferencesWithCache _prefs;

  static Future<StorageService> create() async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {
          _highScoreKey,
          _gamesPlayedKey,
          _soundEnabledKey,
          _vibrationEnabledKey,
        },
      ),
    );
    return StorageService._(prefs);
  }

  int get highScore => _prefs.getInt(_highScoreKey) ?? 0;
  int get gamesPlayed => _prefs.getInt(_gamesPlayedKey) ?? 0;
  bool get soundEnabled => _prefs.getBool(_soundEnabledKey) ?? true;
  bool get vibrationEnabled => _prefs.getBool(_vibrationEnabledKey) ?? true;

  Future<void> setSoundEnabled(bool value) =>
      _prefs.setBool(_soundEnabledKey, value);

  Future<void> setVibrationEnabled(bool value) =>
      _prefs.setBool(_vibrationEnabledKey, value);

  /// Records a finished run. Returns true when [score] is a new high score.
  /// The in-memory cache updates immediately; disk writes happen async.
  bool submitScore(int score) {
    _prefs.setInt(_gamesPlayedKey, gamesPlayed + 1);
    if (score > highScore) {
      _prefs.setInt(_highScoreKey, score);
      return true;
    }
    return false;
  }
}
