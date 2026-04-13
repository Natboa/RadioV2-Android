import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../designsystem/tv_colors.dart';
import '../shell/tv_shell.dart';

/// TV-friendly search bar.
/// - Arrow keys navigate away rather than moving the text cursor.
/// - Keyboard only opens when the user explicitly presses Enter/Select
///   (never auto-shows on D-pad focus passing through).
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

  /// Whether the user has explicitly activated the field (pressed Enter/Select).
  /// Only when true does the keyboard appear.
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;

        // Enter / Select → open keyboard and enter editing mode.
        if (key == LogicalKeyboardKey.select ||
            key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter) {
          if (!_isEditing) {
            setState(() => _isEditing = true);
            // Show the on-screen keyboard after the readOnly flag flips.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                SystemChannels.textInput.invokeMethod('TextInput.show');
              }
            });
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored; // Let TextField handle Enter while typing
        }

        // Back / Escape → exit editing mode.
        if (key == LogicalKeyboardKey.escape ||
            key == LogicalKeyboardKey.goBack) {
          if (_isEditing) {
            setState(() => _isEditing = false);
            SystemChannels.textInput.invokeMethod('TextInput.hide');
            return KeyEventResult.handled;
          }
        }

        // D-pad left / up → move focus left (toward the rail).
        if (key == LogicalKeyboardKey.arrowLeft ||
            key == LogicalKeyboardKey.arrowUp) {
          if (!_isEditing) {
            final moved = FocusTraversalGroup.of(context)
                .inDirection(node, TraversalDirection.left);
            if (!moved) TvShellScope.of(context)?.focusRail();
            return KeyEventResult.handled;
          }
        }

        // D-pad down / right → move focus to content below (when not editing).
        if (key == LogicalKeyboardKey.arrowDown ||
            key == LogicalKeyboardKey.arrowRight) {
          if (!_isEditing) {
            FocusScope.of(context).focusInDirection(TraversalDirection.down);
            return KeyEventResult.handled;
          }
        }

        return KeyEventResult.ignored;
      },
    );

    // When focus is lost, always leave editing mode and ensure keyboard hides.
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      setState(() => _isEditing = false);
    }
    if (_focusNode.hasFocus && !_isEditing) {
      // Actively suppress the keyboard that Flutter would show by default
      // when a TextField receives focus.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusNode.hasFocus && !_isEditing) {
          SystemChannels.textInput.invokeMethod('TextInput.hide');
        }
      });
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
          // readOnly: true prevents the system from auto-opening the keyboard
          // when the field is focused without the user pressing Enter/Select.
          readOnly: !_isEditing,
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
                        setState(() => _isEditing = false);
                        SystemChannels.textInput.invokeMethod('TextInput.hide');
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
