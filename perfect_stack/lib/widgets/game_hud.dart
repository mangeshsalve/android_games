import 'package:flutter/material.dart';

import '../game/perfect_stack_game.dart';
import '../models/game_phase.dart';
import '../utils/app_colors.dart';
import 'round_icon_button.dart';

/// Score display and pause button. Everything except the button ignores
/// pointers so taps fall through to the game.
class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.game,
    required this.best,
    required this.onPause,
  });

  final PerfectStackGame game;
  final int best;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: ValueListenableBuilder<GamePhase>(
                  valueListenable: game.phase,
                  // The overlays show their own score; avoid duplicating it.
                  builder: (context, phase, child) => AnimatedOpacity(
                    opacity:
                        phase == GamePhase.playing || phase == GamePhase.dying
                        ? 1
                        : 0,
                    duration: const Duration(milliseconds: 200),
                    child: child,
                  ),
                  child: ValueListenableBuilder<int>(
                    valueListenable: game.score,
                    builder: (context, score, _) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AnimatedScore(score: score),
                        Text(
                          'BEST  ${score > best ? score : best}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: Align(
              alignment: const Alignment(0, -0.3),
              child: _TapHint(game: game),
            ),
          ),
          Positioned(
            top: 12,
            right: 16,
            child: ValueListenableBuilder<GamePhase>(
              valueListenable: game.phase,
              builder: (context, phase, _) => AnimatedOpacity(
                opacity: phase == GamePhase.playing ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: phase != GamePhase.playing,
                  child: RoundIconButton(
                    icon: Icons.pause_rounded,
                    tooltip: 'Pause',
                    onPressed: onPause,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Big score number that "pops" every time it changes.
class _AnimatedScore extends StatelessWidget {
  const _AnimatedScore({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(score),
      tween: Tween(begin: score == 0 ? 1 : 1.3, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Text(
        '$score',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 72,
          height: 1.1,
          fontWeight: FontWeight.w900,
          shadows: [Shadow(color: Color(0x55000000), blurRadius: 12)],
        ),
      ),
    );
  }
}

/// "TAP TO DROP" hint shown until the first block is placed.
class _TapHint extends StatelessWidget {
  const _TapHint({required this.game});

  final PerfectStackGame game;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([game.score, game.phase]),
      builder: (context, _) {
        final visible =
            game.score.value == 0 && game.phase.value == GamePhase.playing;
        return AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_rounded, color: Colors.white70, size: 22),
              SizedBox(width: 8),
              Text(
                'TAP TO DROP',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
