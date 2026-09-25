import 'package:flutter/material.dart';

/// Dimmed full-screen layer with content that fades and slides in.
/// It absorbs taps so nothing reaches the game underneath.
class OverlayPanel extends StatelessWidget {
  const OverlayPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => ColoredBox(
        color: Colors.black.withValues(alpha: 0.72 * t),
        child: Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - t)),
            child: child,
          ),
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: child,
          ),
        ),
      ),
    );
  }
}
