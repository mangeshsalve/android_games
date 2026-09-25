import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/perfect_stack_game.dart';
import '../models/game_phase.dart';
import '../models/game_result.dart';
import '../services/app_services.dart';
import '../widgets/game_hud.dart';
import '../widgets/pause_overlay.dart';
import 'game_over_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Created once per screen so rebuilds never create a second game loop.
  late final PerfectStackGame _game = PerfectStackGame(
    sound: widget.services.sound,
    haptics: widget.services.haptics,
    onGameOver: _handleGameOver,
  );

  late int _bestBeforeRun = widget.services.storage.highScore;
  GameResult? _result;
  bool _adLoading = false;
  bool _busy = false;

  @override
  void dispose() {
    // The GameWidget (a descendant) has already detached the game here.
    _game.score.dispose();
    _game.phase.dispose();
    super.dispose();
  }

  void _handleGameOver(int score) {
    final storage = widget.services.storage;
    storage.submitScore(score);
    setState(() {
      _result = GameResult(
        score: score,
        best: storage.highScore,
        isNewBest: score > _bestBeforeRun,
      );
    });
  }

  void _handleBack() {
    switch (_game.phase.value) {
      case GamePhase.playing:
        _game.pause();
      case GamePhase.paused:
        _game.resume();
      case GamePhase.dying:
        break;
      case GamePhase.gameOver:
        _goHome();
    }
  }

  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);
    widget.services.haptics.button();
    await widget.services.ads.onRunFinished();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = null;
      _bestBeforeRun = widget.services.storage.highScore;
    });
    _game.restart();
  }

  Future<void> _goHome() async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.services.ads.onRunFinished();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  /// Leaving mid-run from the pause menu still keeps a new high score.
  void _quitFromPause() {
    widget.services.storage.submitScore(_game.score.value);
    Navigator.of(context).pop();
  }

  Future<void> _watchAdToContinue() async {
    if (_adLoading || _busy) return;
    setState(() => _adLoading = true);
    final rewarded = await widget.services.ads.showRewardedForContinue();
    if (!mounted) return;
    setState(() => _adLoading = false);
    if (rewarded) {
      setState(() => _result = null);
      _game.continueRun();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad not available right now.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              // Listener reacts on pointer-down (no gesture-arena delay),
              // which makes drops feel instant.
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => _game.drop(),
                child: GameWidget(game: _game),
              ),
            ),
            Positioned.fill(
              child: GameHud(
                game: _game,
                best: _bestBeforeRun,
                onPause: _game.pause,
              ),
            ),
            Positioned.fill(
              child: ValueListenableBuilder<GamePhase>(
                valueListenable: _game.phase,
                builder: (context, phase, _) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _buildOverlay(phase),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay(GamePhase phase) {
    final result = _result;
    if (phase == GamePhase.paused) {
      return PauseOverlay(
        key: const ValueKey('pause'),
        onResume: _game.resume,
        onHome: _quitFromPause,
      );
    }
    if (phase == GamePhase.gameOver && result != null) {
      return GameOverScreen(
        key: const ValueKey('gameOver'),
        result: result,
        canContinue:
            !_game.continueUsed && widget.services.ads.canOfferContinue,
        continueLoading: _adLoading,
        busy: _busy,
        onRetry: _retry,
        onContinue: _watchAdToContinue,
        onHome: _goHome,
      );
    }
    return const SizedBox.shrink(key: ValueKey('none'));
  }
}
