import 'package:flutter/material.dart';
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

  const TvFocusCard({
    super.key,
    required this.child,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
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
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _focused ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              border: _focused
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
