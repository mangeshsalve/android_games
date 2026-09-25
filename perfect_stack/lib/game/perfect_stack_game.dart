import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../models/block_palette.dart';
import '../models/game_phase.dart';
import '../models/stack_block.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';
import 'components/background_component.dart';
import 'components/block_component.dart';
import 'components/debris_component.dart';
import 'components/floating_text_component.dart';
import 'components/ripple_component.dart';
import 'systems/difficulty.dart';
import 'systems/stack_logic.dart';

/// The core stacking game.
///
/// All gameplay happens in a fixed-width world ([worldWidth] units wide);
/// the camera zoom adapts it to any screen size, so resizing never changes
/// the rules. Input is forwarded from Flutter via [drop], and UI state is
/// exposed through [score] and [phase] notifiers.
class PerfectStackGame extends FlameGame {
  PerfectStackGame({
    required this.sound,
    required this.haptics,
    this.difficulty = const DifficultyConfig.normal(),
    this.palette = BlockPalette.classic,
    this.onGameOver,
    math.Random? random,
  }) : _random = random ?? math.Random();

  static const double worldWidth = 400;
  static const double blockHeight = 34;
  static const double initialBlockWidth = 240;

  /// Minimum world height that must fit on screen; limits zoom on
  /// wide/short screens such as tablets.
  static const double minVisibleHeight = 640;

  /// How far (from the centre) the moving block travels on each side.
  static const double swingAmplitude = 215;

  /// Where the top of the stack sits vertically on screen (0 = top).
  static const double focusScreenFraction = 0.58;

  static const double _gameOverDelay = 0.9;

  final SoundService sound;
  final HapticService haptics;
  final DifficultyConfig difficulty;
  final BlockPalette palette;

  /// Called once per death, just before [phase] becomes [GamePhase.gameOver].
  final ValueChanged<int>? onGameOver;

  final math.Random _random;

  final ValueNotifier<int> score = ValueNotifier(0);
  final ValueNotifier<GamePhase> phase = ValueNotifier(GamePhase.playing);

  bool _continueUsed = false;
  bool get continueUsed => _continueUsed;

  final List<StackBlock> _stack = [];
  late final BackgroundComponent _background;
  BlockComponent? _moving;
  double _movingOffset = 0;
  double _movingDirection = 1;
  double _movingSpeed = 0;
  double _startHue = 0;
  int _perfectStreak = 0;
  double _deathTimer = 0;
  double _cameraFocusY = 0;
  // Reused every frame; Viewfinder.position returns a copy, so the camera
  // must be moved through its setter.
  final Vector2 _cameraPosition = Vector2(worldWidth / 2, 0);

  int get _level => _stack.length - 1;
  double _rowTop(int row) => -row * blockHeight;
  double _hueFor(int row) => palette.hueForRow(_startHue, row);

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = const Anchor(0.5, focusScreenFraction);
    _startHue = _random.nextDouble() * 360;
    _background = BackgroundComponent(palette: palette, hue: _startHue);
    camera.backdrop.add(_background);
    _updateZoom(size);
    _setupNewRun();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updateZoom(size);
  }

  void _updateZoom(Vector2 size) {
    if (size.x <= 0 || size.y <= 0) return;
    camera.viewfinder.zoom = math.min(
      size.x / worldWidth,
      size.y / minVisibleHeight,
    );
  }

  // ---------------------------------------------------------------------
  // Run lifecycle
  // ---------------------------------------------------------------------

  void _setupNewRun() {
    world.removeAll(world.children.toList());
    _stack.clear();
    _moving = null;
    _perfectStreak = 0;
    _deathTimer = 0;
    _continueUsed = false;
    score.value = 0;

    _startHue = _random.nextDouble() * 360;
    _background.snapTo(_startHue);

    const foundation = StackBlock(
      left: (worldWidth - initialBlockWidth) / 2,
      width: initialBlockWidth,
    );
    _stack.add(foundation);
    // A very tall foundation so the tower always appears grounded.
    world.add(
      BlockComponent(
        position: Vector2(foundation.left, 0),
        size: Vector2(foundation.width, 4000),
        faceHeight: blockHeight,
        hue: _hueFor(0),
        palette: palette,
      ),
    );

    _spawnMovingBlock();
    _cameraFocusY = _targetFocusY;
    _moveCamera();
    phase.value = GamePhase.playing;
  }

  /// Starts a fresh run. Safe to call at any time.
  void restart() {
    if (paused) resumeEngine();
    _setupNewRun();
  }

  /// Continues the current run after a rewarded ad. Allowed once per run.
  void continueRun() {
    if (phase.value != GamePhase.gameOver || _continueUsed) return;
    _continueUsed = true;
    _perfectStreak = 0;
    if (paused) resumeEngine();
    _spawnMovingBlock();
    phase.value = GamePhase.playing;
  }

  void pause() {
    if (phase.value != GamePhase.playing) return;
    phase.value = GamePhase.paused;
    pauseEngine();
  }

  void resume() {
    if (phase.value != GamePhase.paused) return;
    phase.value = GamePhase.playing;
    resumeEngine();
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    // Show the pause menu instead of silently freezing when backgrounded,
    // so the player is never surprised by a moving block on return.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      pause();
    }
    super.lifecycleStateChange(state);
  }

  void _moveCamera() {
    _cameraPosition.y = _cameraFocusY;
    camera.viewfinder.position = _cameraPosition;
  }

  // ---------------------------------------------------------------------
  // Gameplay
  // ---------------------------------------------------------------------

  double get _targetFocusY => _rowTop(_stack.length - 1);

  void _spawnMovingBlock() {
    final top = _stack.last;
    final row = _stack.length;
    _movingDirection = row.isEven ? 1 : -1;
    _movingOffset = -_movingDirection * swingAmplitude;
    _movingSpeed = difficulty.speedFor(_level);

    final block = BlockComponent(
      position: Vector2(_movingLeft(top.width), _rowTop(row)),
      size: Vector2(top.width, blockHeight),
      hue: _hueFor(row),
      palette: palette,
      priority: 1,
    );
    _moving = block;
    world.add(block);
  }

  double _movingLeft(double width) =>
      worldWidth / 2 + _movingOffset - width / 2;

  /// Called on every tap. Stops the moving block and resolves placement.
  void drop() {
    final moving = _moving;
    if (phase.value != GamePhase.playing || moving == null) return;

    final top = _stack.last;
    final row = _stack.length;
    final dropped = StackBlock(left: moving.position.x, width: moving.size.x);
    final result = StackLogic.resolve(
      top: top,
      dropped: dropped,
      perfectTolerance: difficulty.perfectToleranceFor(_level),
    );

    if (result.isMiss) {
      _handleMiss(moving, row);
      return;
    }

    var placed = result.placed!;
    if (result.isPerfect) {
      _perfectStreak++;
      if (_perfectStreak >= difficulty.perfectStreakForGrowth) {
        placed = StackLogic.grow(
          placed,
          difficulty.growthPerPerfect,
          initialBlockWidth,
        );
      }
    } else {
      _perfectStreak = 0;
    }

    moving
      ..position.x = placed.left
      ..size.x = placed.width
      ..priority = 0
      ..flash();
    _stack.add(placed);
    _moving = null;

    final debris = result.debris;
    if (debris != null) {
      world.add(
        DebrisComponent.fromBlock(
          left: debris.left,
          top: _rowTop(row),
          width: debris.width,
          height: blockHeight,
          hue: _hueFor(row),
          palette: palette,
          direction: debris.center < placed.center ? -1 : 1,
          removeBelowY: _cameraFocusY + 2000,
        ),
      );
    }

    if (result.isPerfect) {
      final rect = Rect.fromLTWH(
        placed.left,
        _rowTop(row),
        placed.width,
        blockHeight,
      );
      world.add(RippleComponent(rect: rect));
      world.add(
        FloatingTextComponent(
          text: _perfectStreak > 1 ? 'PERFECT ×$_perfectStreak' : 'PERFECT',
          position: Vector2(placed.center, _rowTop(row) - 28),
        ),
      );
      sound.playPerfect(_perfectStreak);
      haptics.perfect();
    } else {
      sound.playPlace();
      haptics.place();
    }

    score.value++;
    _background.targetHue = _hueFor(row);
    _spawnMovingBlock();
  }

  void _handleMiss(BlockComponent moving, int row) {
    moving.removeFromParent();
    _moving = null;
    _perfectStreak = 0;
    world.add(
      DebrisComponent.fromBlock(
        left: moving.position.x,
        top: _rowTop(row),
        width: moving.size.x,
        height: blockHeight,
        hue: _hueFor(row),
        palette: palette,
        direction: moving.position.x + moving.size.x / 2 < _stack.last.center
            ? -1
            : 1,
        removeBelowY: _cameraFocusY + 2000,
      ),
    );
    sound.playFail();
    haptics.fail();
    _deathTimer = _gameOverDelay;
    phase.value = GamePhase.dying;
  }

  @override
  void update(double dt) {
    // Clamp long frames (e.g. after a hitch) so blocks never teleport.
    final step = math.min(dt, 1 / 30);
    super.update(step);

    final moving = _moving;
    if (phase.value == GamePhase.playing && moving != null) {
      _movingOffset += _movingDirection * _movingSpeed * step;
      if (_movingOffset > swingAmplitude) {
        _movingOffset = swingAmplitude;
        _movingDirection = -1;
      } else if (_movingOffset < -swingAmplitude) {
        _movingOffset = -swingAmplitude;
        _movingDirection = 1;
      }
      moving.position.x = _movingLeft(moving.size.x);
    }

    final target = _targetFocusY;
    _cameraFocusY += (target - _cameraFocusY) * (step * 7).clamp(0.0, 1.0);
    _moveCamera();

    if (phase.value == GamePhase.dying) {
      _deathTimer -= step;
      if (_deathTimer <= 0) {
        onGameOver?.call(score.value);
        phase.value = GamePhase.gameOver;
        // Nothing moves behind the game-over panel; save battery.
        pauseEngine();
      }
    }
  }
}
