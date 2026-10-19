import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import 'overlay_panel.dart';
import 'pill_button.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.onResume, required this.onHome});

  final VoidCallback onResume;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return OverlayPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'PAUSED',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 40),
          PillButton(
            label: 'RESUME',
            icon: Icons.play_arrow_rounded,
            onPressed: onResume,
          ),
          const SizedBox(height: 14),
          PillButton(
            label: 'HOME',
            icon: Icons.home_rounded,
            primary: false,
            onPressed: onHome,
          ),
        ],
      ),
    );
  }
}
