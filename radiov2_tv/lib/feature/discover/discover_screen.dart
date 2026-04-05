import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/model/category.dart';
import '../../core/model/group.dart';
import '../../designsystem/tv_colors.dart';
import '../../designsystem/tv_focus.dart';

import 'discover_notifier_tv.dart';
import 'discover_state_tv.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(discoverTvNotifierProvider);

    return switch (state) {
      DiscoverTvLoading() => const Center(child: CircularProgressIndicator()),
      DiscoverTvError(:final message) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: TvColors.error, size: 48),
              const SizedBox(height: 16),
              Text(message,
                  style: const TextStyle(color: TvColors.onSurfaceVariant)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(discoverTvNotifierProvider.notifier).retry(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      DiscoverTvSuccess(:final categories) =>
        _DiscoverContent(categories: categories),
    };
  }
}

class _DiscoverContent extends StatelessWidget {
  final List<CategoryWithGroups> categories;

  const _DiscoverContent({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 48, right: 48, top: 48, bottom: 24),
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
            height: 220,
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
    final imagePath =
        'assets/images/groups/${group.name}.png';

    return TvFocusCard(
      autofocus: autofocus,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      onTap: () => context.go('/discover/group/${group.id}'),
      child: SizedBox(
        width: 220,
        height: 220,
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
