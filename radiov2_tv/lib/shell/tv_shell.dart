import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../designsystem/tv_colors.dart';
import '../designsystem/tv_focus.dart';

class TvShell extends StatelessWidget {
  final StatefulNavigationShell shell;

  const TvShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TvColors.background,
      body: FocusTraversalGroup(
        child: Row(
          children: [
            TvSideRail(
              currentIndex: shell.currentIndex,
              onSelect: (index) =>
                  shell.goBranch(index, initialLocation: index == shell.currentIndex),
            ),
            Expanded(
              child: FocusTraversalGroup(
                child: shell,
              ),
            ),
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
  _RailItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
  _RailItem(icon: Icons.explore_outlined, selectedIcon: Icons.explore, label: 'Discover'),
  _RailItem(icon: Icons.radio_outlined, selectedIcon: Icons.radio, label: 'Browse'),
  _RailItem(icon: Icons.favorite_outline, selectedIcon: Icons.favorite, label: 'Favourites'),
  _RailItem(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings'),
];

class TvSideRail extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onSelect;

  const TvSideRail({
    super.key,
    required this.currentIndex,
    required this.onSelect,
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
  final VoidCallback onTap;

  const _RailButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.label,
      preferBelow: false,
      child: TvFocusCard(
        onTap: onTap,
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
