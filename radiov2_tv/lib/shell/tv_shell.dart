import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../designsystem/tv_colors.dart';
import '../designsystem/tv_focus.dart';

class TvShell extends StatefulWidget {
  final StatefulNavigationShell shell;

  const TvShell({super.key, required this.shell});

  @override
  State<TvShell> createState() => _TvShellState();
}

class _TvShellState extends State<TvShell> {
  final _firstRailFocus = FocusNode();
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _firstRailFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _firstRailFocus.dispose();
    super.dispose();
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
      child: Scaffold(
        backgroundColor: TvColors.background,
        body: Row(
          children: [
            TvSideRail(
              currentIndex: widget.shell.currentIndex,
              firstButtonFocusNode: _firstRailFocus,
              onSelect: (index) => widget.shell.goBranch(
                  index,
                  initialLocation: index == widget.shell.currentIndex),
            ),
            Expanded(child: widget.shell),
          ],
        ),
      ),
    );
  }
}

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
  final FocusNode? firstButtonFocusNode;

  const TvSideRail({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    this.firstButtonFocusNode,
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
              focusNode: i == 0 ? firstButtonFocusNode : null,
              onTap: () => onSelect(i),
            ),
        ],
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  final _RailItem item;
  final bool selected;
  final FocusNode? focusNode;
  final VoidCallback onTap;

  const _RailButton({
    required this.item,
    required this.selected,
    required this.onTap,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.label,
      preferBelow: false,
      child: TvFocusCard(
        onTap: onTap,
        focusNode: focusNode,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Container(
          width: 56,
          height: 56,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            color: selected ? TvColors.accent.withAlpha(40) : Colors.transparent,
          ),
          child: Icon(
            selected ? item.selectedIcon : item.icon,
            color: selected ? TvColors.accent : TvColors.onSurfaceVariant,
            size: 28,
          ),
        ),
      ),
    );
  }
}
