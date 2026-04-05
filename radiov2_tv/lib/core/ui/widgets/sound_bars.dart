import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../designsystem/colors.dart';

/// Animated equalizer bars — 5 bars that bounce independently.
/// Matches the desktop SoundbarAnimation control.
/// Set [isAnimating] to true while a station is playing.
class SoundBars extends StatefulWidget {
  final bool isAnimating;

  const SoundBars({super.key, required this.isAnimating});

  @override
  State<SoundBars> createState() => _SoundBarsState();
}

class _SoundBarsState extends State<SoundBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Phase offsets per bar (radians) — gives each bar a different rhythm
  static const _phases = [0.0, 1.1, 2.3, 0.7, 1.8];
  static const _barWidth = 3.0;
  static const _barGap = 2.5;
  static const _maxH = 16.0;
  static const _minH = 3.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isAnimating) _controller.repeat();
  }

  @override
  void didUpdateWidget(SoundBars old) {
    super.didUpdateWidget(old);
    if (widget.isAnimating && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isAnimating && _controller.isAnimating) {
      _controller.animateTo(0, duration: const Duration(milliseconds: 200));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalW =
        _barWidth * _phases.length + _barGap * (_phases.length - 1);

    return SizedBox(
      width: totalW,
      height: _maxH,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(_phases.length, (i) {
              final t = _controller.value * 2 * math.pi + _phases[i];
              final h = _minH + (_maxH - _minH) * (math.sin(t) * 0.5 + 0.5);
              return Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : _barGap),
                child: Container(
                  width: _barWidth,
                  height: h,
                  decoration: BoxDecoration(
                    color: RadioV2Colors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
