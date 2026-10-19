import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import 'storage_service.dart';

/// Short sound effects played through small pre-loaded audio pools so they
/// start with minimal latency. All failures are swallowed: the game must
/// never crash because audio is unavailable.
class SoundService {
  SoundService(this._storage);

  static const _placeFile = 'place.wav';
  static const _failFile = 'fail.wav';
  static const _perfectFiles = [
    'perfect_1.wav',
    'perfect_2.wav',
    'perfect_3.wav',
    'perfect_4.wav',
    'perfect_5.wav',
    'perfect_6.wav',
  ];

  final StorageService _storage;

  AudioPool? _place;
  AudioPool? _fail;
  final List<AudioPool> _perfect = [];
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _place = await FlameAudio.createPool(_placeFile, maxPlayers: 4);
      _fail = await FlameAudio.createPool(_failFile, maxPlayers: 1);
      for (final file in _perfectFiles) {
        _perfect.add(await FlameAudio.createPool(file, maxPlayers: 2));
      }
    } catch (error) {
      debugPrint('SoundService: audio unavailable ($error)');
    }
  }

  void playPlace() => _play(_place, volume: 0.7);

  void playFail() => _play(_fail, volume: 0.8);

  /// Each consecutive perfect drop plays a higher note.
  void playPerfect(int streak) {
    if (_perfect.isEmpty) return;
    final index = (streak - 1).clamp(0, _perfect.length - 1);
    _play(_perfect[index], volume: 0.8);
  }

  void _play(AudioPool? pool, {double volume = 1}) {
    if (pool == null || !_storage.soundEnabled) return;
    unawaited(_start(pool, volume));
  }

  Future<void> _start(AudioPool pool, double volume) async {
    try {
      await pool.start(volume: volume);
    } catch (error) {
      debugPrint('SoundService: failed to play ($error)');
    }
  }
}
