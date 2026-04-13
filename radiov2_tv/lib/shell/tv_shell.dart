import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../designsystem/tv_colors.dart';
import '../designsystem/tv_focus.dart';
import '../feature/player/player_notifier.dart';

/// Exposes a [focusRail] callback so any descendant widget can explicitly
/// jump focus back to the side-rail (used as a fallback when D-pad left
/// traversal cannot find a focusable node within the content FocusScope).
class TvShellScope extends InheritedWidget {
  final VoidCallback focusRail;

  const TvShellScope({
    super.key,
    required this.focusRail,
    required super.child,
  });

  static TvShellScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TvShellScope>();

  @override
  bool updateShouldNotify(TvShellScope oldWidget) => false;
}

class TvShell extends StatefulWidget {
  final StatefulNavigationShell shell;

  const TvShell({super.key, required this.shell});

  @override
  State<TvShell> createState() => _TvShellState();
}

class _TvShellState extends State<TvShell> {
  // One FocusNode per rail item so we can focus any of them individually.
  final _railFocusNodes =
      List.generate(_railItems.length, (_) => FocusNode());
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _railFocusNodes[widget.shell.currentIndex].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final n in _railFocusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  // Focus the currently-selected rail button (called by descendants via
  // TvShellScope when D-pad left reaches the rail edge).
  void _focusRail() {
    _railFocusNodes[widget.shell.currentIndex].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        final now = DateTime.now();
        final last = _lastBackPress;
        if (last != null && now.difference(last) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
          return;
        }
        _lastBackPress = now;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: TvShellScope(
        focusRail: _focusRail,
        child: Scaffold(
          backgroundColor: TvColors.background,
          body: Row(
            children: [
              TvSideRail(
                currentIndex: widget.shell.currentIndex,
                railFocusNodes: _railFocusNodes,
                onSelect: (index) => widget.shell.goBranch(
                    index,
                    initialLocation: index == widget.shell.currentIndex),
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: widget.shell),
                    const _NowPlayingBar(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Now-playing bar
// ---------------------------------------------------------------------------

class _NowPlayingBar extends ConsumerWidget {
  const _NowPlayingBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerNotifierProvider);
    if (player.isIdle) return const SizedBox.shrink();

    final station = player.station!;
    final icyText = player.nowPlayingText;

    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: TvColors.surface,
        border: Border(
          top: BorderSide(color: TvColors.accent, width: 2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Station logo
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: station.logoUrl != null && station.logoUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: station.logoUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const _LogoPlaceholder(),
                    errorWidget: (_, __, ___) => const _LogoPlaceholder(),
                  )
                : const _LogoPlaceholder(),
          ),
          const SizedBox(width: 16),
          // Station name + icy metadata
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TvColors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (icyText != null && icyText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    icyText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TvColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Live indicator dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: player.isPlaying ? TvColors.accent : TvColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              color: player.isPlaying ? TvColors.accent : TvColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 44,
      height: 44,
      child: ColoredBox(
        color: TvColors.surfaceVariant,
        child: Icon(Icons.radio, color: TvColors.onSurfaceVariant, size: 24),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Side rail
// ---------------------------------------------------------------------------

class _RailItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _RailItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

const _railItems = [
  _RailItem(icon: Icons.radio_outlined, selectedIcon: Icons.radio, label: 'Browse'),
  _RailItem(icon: Icons.explore_outlined, selectedIcon: Icons.explore, label: 'Discover'),
  _RailItem(icon: Icons.favorite_outline, selectedIcon: Icons.favorite, label: 'Favourites'),
  _RailItem(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings'),
];

class TvSideRail extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onSelect;
  final List<FocusNode> railFocusNodes;

  const TvSideRail({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.railFocusNodes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      color: TvColors.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < _railItems.length; i++)
            _RailButton(
              item: _railItems[i],
              selected: i == currentIndex,
              focusNode: railFocusNodes[i],
              onTap: () => onSelect(i),
            ),
        ],
      ),
    );
  }
}

/// Rail button that navigates to its page as soon as it receives D-pad focus,
/// so the user doesn't need to press OK/Select to switch pages.
/// Focus is kept on the rail button after the shell rebuilds.
class _RailButton extends StatefulWidget {
  final _RailItem item;
  final bool selected;
  final FocusNode focusNode;
  final VoidCallback onTap;

  const _RailButton({
    required this.item,
    required this.selected,
    required this.focusNode,
    required this.onTap,
  });

  @override
  State<_RailButton> createState() => _RailButtonState();
}

class _RailButtonState extends State<_RailButton> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(_RailButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      widget.focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted || !widget.focusNode.hasFocus) return;
    // Navigate to this page immediately on focus.
    widget.onTap();
    // Re-request focus after the navigation rebuilds the shell so focus
    // stays on the rail and doesn't jump into the page content.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.focusNode.hasFocus) {
        widget.focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.item.label,
      preferBelow: false,
      child: TvFocusCard(
        onTap: widget.onTap,
        focusNode: widget.focusNode,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Container(
          width: 56,
          height: 56,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            color: widget.selected
                ? TvColors.accent.withAlpha(40)
                : Colors.transparent,
          ),
          child: Icon(
            widget.selected ? widget.item.selectedIcon : widget.item.icon,
            color: widget.selected ? TvColors.accent : TvColors.onSurfaceVariant,
            size: 28,
          ),
        ),
      ),
    );
  }
}
