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
    return Padding(
      padding: const EdgeInsets.only(left: 48, right: 48, bottom: 24),
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final cat = categories[i];
          if (cat.groups.isEmpty) return const SizedBox.shrink();
          return _CategoryRow(
            category: cat,
            autofocusFirst: i == 0,
          );
        },
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryWithGroups category;
  final bool autofocusFirst;

  const _CategoryRow({required this.category, this.autofocusFirst = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.category.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 143,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: category.groups.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, i) => _GroupCard(
                group: category.groups[i],
                autofocus: autofocusFirst && i == 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final Group group;
  final bool autofocus;

  const _GroupCard({required this.group, this.autofocus = false});

  @override
  Widget build(BuildContext context) {
    final imagePath = 'assets/images/groups/${group.name}.png';

    return TvFocusCard(
      autofocus: autofocus,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      focusScale: 1.12,
      onTap: () => context.go('/discover/group/${group.id}'),
      child: SizedBox(
        width: 143,
        height: 143,
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

