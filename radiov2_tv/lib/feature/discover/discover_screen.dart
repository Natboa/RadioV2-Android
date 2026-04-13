import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/model/category.dart';
import '../../core/model/group.dart';
import '../../designsystem/tv_colors.dart';
import '../../widgets/tv_search_bar.dart';
import '../../designsystem/tv_focus.dart';

import 'discover_notifier_tv.dart';
import 'discover_state_tv.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoverTvNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSearchBar(
          controller: _searchController,
          hintText: 'Search genres…',
          onChanged: (q) => setState(() => _query = q.toLowerCase()),
        ),
        Expanded(
          child: switch (state) {
            DiscoverTvLoading() =>
              const Center(child: CircularProgressIndicator()),
            DiscoverTvError(:final message) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: TvColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text(message,
                        style: const TextStyle(
                            color: TvColors.onSurfaceVariant)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(discoverTvNotifierProvider.notifier).retry(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            DiscoverTvSuccess(:final categories) => _DiscoverContent(
                categories: _query.isEmpty
                    ? categories
                    : _filterCategories(categories, _query),
              ),
          },
        ),
      ],
    );
  }

  List<CategoryWithGroups> _filterCategories(
      List<CategoryWithGroups> cats, String query) {
    return cats
        .map((c) => CategoryWithGroups(
              category: c.category,
              groups: c.groups
                  .where((g) => g.name.toLowerCase().contains(query))
                  .toList(),
            ))
        .where((c) =>
            c.groups.isNotEmpty ||
            c.category.name.toLowerCase().contains(query))
        .toList();
  }
}

// ── Content ───────────────────────────────────────────────────────────────────

class _DiscoverContent extends StatelessWidget {
  final List<CategoryWithGroups> categories;

  const _DiscoverContent({required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(
        child: Text(
          'No results.',
          style: TextStyle(color: TvColors.onSurfaceVariant, fontSize: 18),
        ),
      );
    }

    final slivers = <Widget>[];
    for (int i = 0; i < categories.length; i++) {
      final cat = categories[i];
      if (cat.groups.isEmpty) continue;

      // Category header — scrolls with the content, never pins/stacks.
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            cat.category.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: TvColors.onBackground,
                ),
          ),
        ),
      ));

      // Horizontal card row.
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: _CategoryHorizontalList(groups: cat.groups),
        ),
      ));
    }
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 24)));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: CustomScrollView(
        // Smooth bouncy physics for animated scroll feel.
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: slivers,
      ),
    );
  }
}

// ── Horizontal card row ───────────────────────────────────────────────────────

/// Row height = card size (165) + 12 vertical padding on each side (24 total)
/// = 189 ≈ 190. This gives enough room for the 1.1× focus-scale to expand
/// without being clipped.
const _kCardSize = 165.0;
const _kRowHeight = 190.0;
const _kRowVerticalPadding = 12.0;

class _CategoryHorizontalList extends StatelessWidget {
  final List<Group> groups;

  const _CategoryHorizontalList({required this.groups});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kRowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Allow focused cards to scale outside the row without being clipped.
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(vertical: _kRowVerticalPadding),
        itemCount: groups.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, i) => _GroupCard(group: groups[i]),
      ),
    );
  }
}

// ── Group card ────────────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final Group group;

  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final imagePath = 'assets/images/groups/${group.name}.png';

    return TvFocusCard(
      autofocus: false,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      focusScale: 1.1,
      onTap: () => context.go('/discover/group/${group.id}'),
      child: SizedBox(
        width: _kCardSize,
        height: _kCardSize,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: TvColors.surfaceVariant,
                  child: Icon(Icons.library_music,
                      color: TvColors.onSurfaceVariant, size: 64),
                ),
              ),
            ),
            // Gradient overlay so text is legible over any image.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 80,
                decoration: const BoxDecoration(
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(12)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xDD000000)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${group.stationCount} stations',
                    style: const TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
