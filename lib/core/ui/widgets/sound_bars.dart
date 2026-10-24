import 'package:flutter/material.dart';

/// A quiet signal mark, not a simulated visualizer. No repeating ticker, even
/// when its row is cached just outside the viewport.
class SoundBars extends StatelessWidget {
  final bool isAnimating;
  const SoundBars({super.key, required this.isAnimating});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
          child: SizedBox(
        width: 15,
        height: 14,
        child: CustomPaint(
            painter: _SignalPainter(
                Theme.of(context).colorScheme.primary, isAnimating)),
      ));
}

class _SignalPainter extends CustomPainter {
  final Color color;
  final bool active;
  _SignalPainter(this.color, this.active);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const heights = [5.0, 11.0, 14.0, 8.0];
    for (var i = 0; i < heights.length; i++) {
      final h = active ? heights[i] : 3.0;
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(i * 4, (14 - h) / 2, 2, h),
              const Radius.circular(1)),
          paint);
    }
  }

  @override
  bool shouldRepaint(_SignalPainter old) =>
      old.color != color || old.active != active;
}
