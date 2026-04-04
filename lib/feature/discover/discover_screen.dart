import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/model/category.dart';
import '../../core/model/group.dart';
import '../../core/ui/widgets/group_card.dart';
import '../../core/designsystem/colors.dart';
import '../../navigation/app_destinations.dart';
import 'discover_notifier.dart';
import 'discover_state.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(discoverNotifierProvider.notifier).setQuery(value);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debounce?.cancel();
    ref.read(discoverNotifierProvider.notifier).setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoverNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: RadioV2Colors.onSurface),
              decoration: InputDecoration(
                hintText: 'Search groups…',
                hintStyle: const TextStyle(color: RadioV2Colors.onSurfaceVariant),
                prefixIcon: const Icon(Icons.search, color: RadioV2Colors.onSurfaceVariant),
                suffixIcon: ValueListenableBuilder(
                  valueListenable: _searchController,
                  builder: (_, value, __) => value.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              color: RadioV2Colors.onSurfaceVariant),
                          onPressed: _clearSearch,
                        )
                      : const SizedBox.shrink(),
                ),
                filled: true,
                fillColor: RadioV2Colors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: switch (state) {
        DiscoverLoading() =>
          const Center(child: CircularProgressIndicator()),
        DiscoverError(:final message) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: RadioV2Colors.error, size: 48),
              const SizedBox(height: 12),
              Text(message),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.read(discoverNotifierProvider.notifier).retry(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        DiscoverSuccess(:final categories, :final searchResults, :final isSearching) =>
          isSearching
              ? _SearchResultsGrid(groups: searchResults!)
              : _CategoriesList(categories: categories),
      },
    );
  }
}

// ── Search results — flat grid of group cards ─────────────────────────────────

class _SearchResultsGrid extends StatelessWidget {
  final List<Group> groups;

  const _SearchResultsGrid({required this.groups});

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const Center(
        child: Text(
          'No groups found',
          style: TextStyle(color: RadioV2Colors.onSurfaceVariant),
        ),
      );
    }

    const cols = 2;
    const hPadding = 16.0;
    const spacing = 12.0;
    // Text area below image: gap(6) + name(~14) + count(~12) = 32
    const textHeight = 32.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSize =
            (constraints.maxWidth - hPadding * 2 - spacing * (cols - 1)) / cols;
        final cellHeight = imageSize + textHeight;

        return GridView.builder(
          padding: const EdgeInsets.all(hPadding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: spacing,
            mainAxisSpacing: 16,
            childAspectRatio: imageSize / cellHeight,
          ),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return GroupCard(
              group: group,
              size: imageSize,
              onTap: () => context.push(AppRoutes.groupDetailPath(group.id)),
            );
          },
        );
      },
    );
  }
}

// ── Normal browse — categories with horizontal rows ───────────────────────────

class _CategoriesList extends StatelessWidget {
  final List<CategoryWithGroups> categories;

  const _CategoriesList({required this.categories});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        for (final catWithGroups in categories)
          if (catWithGroups.groups.isNotEmpty) ...[
            SliverPersistentHeader(
              pinned: false,
              delegate: _CategoryHeaderDelegate(catWithGroups.category.name),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 196, // image(136) + gap(6) + two text lines(~14+12) + v-pad(8*2)
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: catWithGroups.groups.length,
                  itemBuilder: (context, index) {
                    final group = catWithGroups.groups[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GroupCard(
                        group: group,
                        onTap: () => context.push(
                          AppRoutes.groupDetailPath(group.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        // Extra bottom padding so the last row scrolls clear of the mini player (72px)
        const SliverToBoxAdapter(child: SizedBox(height: 88)),
      ],
    );
  }
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;

  _CategoryHeaderDelegate(this.title);

  @override
  double get minExtent => 44;

  @override
  double get maxExtent => 44;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: RadioV2Colors.background,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  @override
  bool shouldRebuild(_CategoryHeaderDelegate oldDelegate) =>
      oldDelegate.title != title;
}
