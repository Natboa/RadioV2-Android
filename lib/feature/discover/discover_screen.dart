import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/model/category.dart';
import '../../core/model/group.dart';
import '../../core/ui/widgets/group_card.dart';
import '../../core/ui/widgets/content_state.dart';
import '../../core/ui/widgets/radio_search_field.dart';
import '../../navigation/app_destinations.dart';
import 'discover_notifier.dart';
import 'discover_state.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});
  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  @override
  void dispose() {
    _search.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    if (q.isEmpty) {
      ref.read(discoverNotifierProvider.notifier).setQuery('');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300),
        () => ref.read(discoverNotifierProvider.notifier).setQuery(q));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoverNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Discover'), actions: [
        IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push(AppRoutes.settings)),
        const SizedBox(width: 12),
      ]),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: RadioSearchField(
                controller: _search,
                hint: 'Find your sound',
                onChanged: _onSearch)),
        Expanded(
            child: switch (state) {
          DiscoverLoading() => const Center(child: CircularProgressIndicator()),
          DiscoverError() => ContentState(
              icon: Icons.cloud_off_rounded,
              title: 'Couldn’t load Discover',
              message:
                  'Your station library is still here. Try loading it again.',
              actionLabel: 'Try again',
              onAction: () =>
                  ref.read(discoverNotifierProvider.notifier).retry()),
          DiscoverSuccess(
            :final categories,
            :final searchResults,
            :final isSearching
          ) =>
            isSearching
                ? _SearchGrid(groups: searchResults!)
                : _CategoryShelves(categories: categories),
        }),
      ]),
    );
  }
}

class _SearchGrid extends StatelessWidget {
  final List<Group> groups;
  const _SearchGrid({required this.groups});
  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const ContentState(
          icon: Icons.search_off_rounded,
          title: 'No sounds found',
          message: 'Try a genre like jazz, soul or ambient.');
    }
    return LayoutBuilder(builder: (context, constraints) {
      final cols = (constraints.maxWidth / 180).floor().clamp(2, 5);
      final size = (constraints.maxWidth - 48 - (cols - 1) * 16) / cols;
      final scaler = MediaQuery.textScalerOf(context);
      final textHeight = scaler.scale(14) * 1.6 + scaler.scale(12) * 1.5 + 16;
      return GridView.builder(
        key: const PageStorageKey('group-search'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 16,
            mainAxisSpacing: 24,
            mainAxisExtent: size + textHeight),
        itemCount: groups.length,
        itemBuilder: (context, i) => GroupCard(
            key: ValueKey(groups[i].id),
            group: groups[i],
            size: size,
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              FocusManager.instance.applyFocusChangesIfNeeded();
              context.push(AppRoutes.groupDetailPath(groups[i].id));
            }),
      );
    });
  }
}

class _CategoryShelves extends StatelessWidget {
  final List<CategoryWithGroups> categories;
  const _CategoryShelves({required this.categories});
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context);
    final textHeight = scale.scale(14) * 1.6 + scale.scale(12) * 1.5 + 18;
    final shelfSize = MediaQuery.sizeOf(context).width < 360 ? 136.0 : 152.0;
    // The outer list AND each shelf are lazy. No shrinkWrap/eager group widgets.
    return ListView.builder(
      key: const PageStorageKey('genre-shelves'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final category = categories[i];
        if (category.groups.isEmpty) return const SizedBox.shrink();
        return Column(
            key: ValueKey(category.category.id),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Text(category.category.name,
                      style: Theme.of(context).textTheme.titleLarge)),
              SizedBox(
                  height: shelfSize + textHeight,
                  child: ListView.separated(
                    key: PageStorageKey('shelf-${category.category.id}'),
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: category.groups.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, j) {
                      final g = category.groups[j];
                      return GroupCard(
                          key: ValueKey(g.id),
                          group: g,
                          size: shelfSize,
                          onTap: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            FocusManager.instance.applyFocusChangesIfNeeded();
                            context.push(AppRoutes.groupDetailPath(g.id));
                          });
                    },
                  )),
              const SizedBox(height: 8),
            ]);
      },
    );
  }
}
