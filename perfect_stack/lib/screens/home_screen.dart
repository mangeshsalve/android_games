import 'package:flutter/material.dart';

import '../services/app_services.dart';
import '../utils/app_colors.dart';
import '../widgets/gradient_background.dart';
import '../widgets/pill_button.dart';
import '../widgets/round_icon_button.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _starting = false;

  Future<void> _play() async {
    if (_starting) return;
    _starting = true;
    widget.services.haptics.button();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(services: widget.services),
      ),
    );
    _starting = false;
    // Refresh the high score shown on this screen.
    if (mounted) setState(() {});
  }

  Future<void> _toggleSound() async {
    final storage = widget.services.storage;
    await storage.setSoundEnabled(!storage.soundEnabled);
    if (mounted) setState(() {});
  }

  Future<void> _toggleVibration() async {
    final storage = widget.services.storage;
    await storage.setVibrationEnabled(!storage.vibrationEnabled);
    widget.services.haptics.button();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final storage = widget.services.storage;
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    RoundIconButton(
                      icon: storage.soundEnabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      tooltip: 'Sound',
                      onPressed: _toggleSound,
                    ),
                    const SizedBox(width: 12),
                    RoundIconButton(
                      icon: storage.vibrationEnabled
                          ? Icons.vibration_rounded
                          : Icons.mobile_off_rounded,
                      tooltip: 'Vibration',
                      onPressed: _toggleVibration,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _DemoStack(),
                        const SizedBox(height: 40),
                        const Text(
                          'PERFECT',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 52,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                          ),
                        ),
                        const Text(
                          'STACK',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 52,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 14,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _BestScoreChip(best: storage.highScore),
                        const SizedBox(height: 44),
                        PillButton(
                          label: 'PLAY',
                          icon: Icons.play_arrow_rounded,
                          onPressed: _play,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Tap to drop. Stack as high as you can.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BestScoreChip extends StatelessWidget {
  const _BestScoreChip({required this.best});

  final int best;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: AppColors.accent,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'HIGH SCORE  $best',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// A tiny looping illustration of the mechanic: the top block slides back
/// and forth over a small tower.
class _DemoStack extends StatefulWidget {
  const _DemoStack();

  @override
  State<_DemoStack> createState() => _DemoStackState();
}

class _DemoStackState extends State<_DemoStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  static const _barHeight = 18.0;
  static const _widths = [150.0, 150.0, 138.0, 138.0, 124.0];
  static const _offsets = [0.0, 0.0, -6.0, -6.0, 1.0];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bar(Color color, double width) => Container(
    width: width,
    height: _barHeight,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(3),
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.homeStack;
    return SizedBox(
      width: 240,
      height: _barHeight * (_widths.length + 1) + 8,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          for (var i = 0; i < _widths.length; i++)
            Positioned(
              bottom: i * _barHeight,
              child: Transform.translate(
                offset: Offset(_offsets[i], 0),
                child: _bar(colors[i], _widths[i]),
              ),
            ),
          Positioned(
            bottom: _widths.length * _barHeight + 8,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = Curves.easeInOut.transform(_controller.value);
                return Transform.translate(
                  offset: Offset((t * 2 - 1) * 60, 0),
                  child: child,
                );
              },
              child: _bar(colors.last, _widths.last),
            ),
          ),
        ],
      ),
    );
  }
}
