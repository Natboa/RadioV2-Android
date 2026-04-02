import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/model/category.dart';
import '../../core/ui/widgets/group_card.dart';
import '../../core/designsystem/colors.dart';
import '../../navigation/app_destinations.dart';
import 'discover_notifier.dart';
import 'discover_state.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(discoverNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: switch (state) {
        DiscoverLoading() =>
          const Center(child: CircularProgressIndicator()),
        DiscoverError(:final message) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: RadioV2Colors.error,
                size: 48,
              ),
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
        DiscoverSuccess(:final categories) => _CategoriesList(
          categories: categories,
        ),
      },
    );
  }
}

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
              pinned: true,
              delegate: _CategoryHeaderDelegate(catWithGroups.category.name),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 180,
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
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
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
      alignment: Alignment.centerLeft,
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
