import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../designsystem/tv_colors.dart';
import '../shell/tv_shell.dart';

/// TV-friendly search bar.
/// Arrow keys navigate away rather than moving the text cursor,
/// so D-pad navigation is never trapped inside the TextField.
class TvSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  const TvSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  @override
  State<TvSearchBar> createState() => _TvSearchBarState();
}

class _TvSearchBarState extends State<TvSearchBar> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.arrowLeft ||
            key == LogicalKeyboardKey.arrowUp) {
          final moved = FocusTraversalGroup.of(context)
              .inDirection(node, TraversalDirection.left);
          if (!moved) TvShellScope.of(context)?.focusRail();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowDown ||
            key == LogicalKeyboardKey.arrowRight) {
          FocusScope.of(context).focusInDirection(TraversalDirection.down);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
    // Auto-show the soft keyboard on Android TV whenever this field gains focus.
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // On Android TV the IME doesn't always appear automatically when a
      // TextField receives focus via D-pad. Force-show it here.
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 48, right: 48, top: 32, bottom: 20),
      child: SizedBox(
        height: 52,
        child: TextField(
          focusNode: _focusNode,
          controller: widget.controller,
          onChanged: widget.onChanged,
          style: const TextStyle(color: TvColors.onSurface, fontSize: 18),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle:
                const TextStyle(color: TvColors.onSurfaceVariant, fontSize: 18),
            prefixIcon: const Icon(Icons.search,
                color: TvColors.onSurfaceVariant, size: 24),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (_, val, __) => val.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      icon: const Icon(Icons.clear,
                          color: TvColors.onSurfaceVariant),
                      onPressed: () {
                        widget.controller.clear();
                        widget.onChanged('');
                      },
                    ),
            ),
            filled: true,
            fillColor: TvColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: TvColors.focusBorder, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
        ),
      ),
    );
  }
}
