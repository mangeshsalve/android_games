import 'package:flutter/material.dart';

import '../models/game_result.dart';
import '../utils/app_colors.dart';
import '../widgets/overlay_panel.dart';
import '../widgets/pill_button.dart';

/// Shown on top of the frozen game when a run ends.
class GameOverScreen extends StatelessWidget {
  const GameOverScreen({
    super.key,
    required this.result,
    required this.canContinue,
    required this.continueLoading,
    required this.busy,
    required this.onRetry,
    required this.onContinue,
    required this.onHome,
  });

  final GameResult result;
  final bool canContinue;
  final bool continueLoading;

  /// True while an interstitial / navigation is in progress.
  final bool busy;
  final VoidCallback onRetry;
  final VoidCallback onContinue;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final locked = busy || continueLoading;
    return OverlayPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'GAME OVER',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${result.score}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 96,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (result.isNewBest)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'NEW BEST!',
                style: TextStyle(
                  color: AppColors.accentDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            )
          else
            Text(
              'BEST  ${result.best}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          const SizedBox(height: 40),
          PillButton(
            label: 'RETRY',
            icon: Icons.replay_rounded,
            loading: busy,
            onPressed: locked ? null : onRetry,
          ),
          if (canContinue) ...[
            const SizedBox(height: 14),
            PillButton(
              label: 'WATCH AD TO CONTINUE',
              icon: Icons.ondemand_video_rounded,
              primary: false,
              loading: continueLoading,
              onPressed: locked ? null : onContinue,
            ),
          ],
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: locked ? null : onHome,
            icon: const Icon(Icons.home_rounded),
            label: const Text('HOME'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
