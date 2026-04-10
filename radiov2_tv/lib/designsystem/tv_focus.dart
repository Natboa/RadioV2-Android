import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../shell/tv_shell.dart';
import 'tv_colors.dart';

/// A reusable focusable card for TV D-pad navigation.
///
/// Wrap any interactive TV element in this widget. On focus it shows a teal
/// border + slight scale; on OK (enter) press it fires [onTap].
class TvFocusCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool autofocus;
  final BorderRadius borderRadius;
  final bool showFocusBorder;
  /// Scale applied to the card when it is focused. Defaults to 1.05.
  final double focusScale;

  const TvFocusCard({
    super.key,
    required this.child,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.showFocusBorder = true,
    this.focusScale = 1.05,
  });

  @override
  State<TvFocusCard> createState() => _TvFocusCardState();
}

class _TvFocusCardState extends State<TvFocusCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (focused) => setState(() => _focused = focused),
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.select ||
            key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter) {
          widget.onTap?.call();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowLeft) {
          final moved = FocusTraversalGroup.of(context)
              .inDirection(node, TraversalDirection.left);
          if (!moved) TvShellScope.of(context)?.focusRail();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowRight) {
          FocusScope.of(context).focusInDirection(TraversalDirection.right);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowUp) {
          FocusScope.of(context).focusInDirection(TraversalDirection.up);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowDown) {
          FocusScope.of(context).focusInDirection(TraversalDirection.down);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _focused ? widget.focusScale : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              border: (_focused && widget.showFocusBorder)
                  ? Border.all(color: TvColors.focusBorder, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
              color: _focused ? TvColors.focusOverlay : Colors.transparent,
            ),
            child: ClipRRect(
              borderRadius: widget.borderRadius,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
