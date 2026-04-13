import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/model/station.dart';
import '../../designsystem/tv_colors.dart';
import '../../widgets/tv_search_bar.dart';
import '../../feature/player/player_notifier.dart';
import '../../navigation/tv_destinations.dart';
import '../../widgets/tv_station_tile.dart';
import 'favourites_notifier_tv.dart';
import 'favourites_state_tv.dart';

class FavouritesScreen extends ConsumerStatefulWidget {
  const FavouritesScreen({super.key});

  @override
  ConsumerState<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends ConsumerState<FavouritesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(favouritesTvNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSearchBar(
          controller: _searchController,
          hintText: 'Search favourites…',
          onChanged: (q) => setState(() => _query = q.toLowerCase()),
        ),
        Expanded(
          child: switch (state) {
            FavouritesTvLoading() =>
              const Center(child: CircularProgressIndicator()),
            FavouritesTvEmpty() => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_outline,
                        color: TvColors.onSurfaceVariant, size: 64),
                    SizedBox(height: 24),
                    Text(
                      'No favourites yet.',
                      style: TextStyle(
                          color: TvColors.onSurfaceVariant, fontSize: 20),
                    ),
                  ],
                ),
              ),
            FavouritesTvError(:final message) => Center(
                child: Text(message,
                    style:
                        const TextStyle(color: TvColors.onSurfaceVariant)),
              ),
            FavouritesTvSuccess(:final stations) => _FavouritesGrid(
                stations: _query.isEmpty
                    ? stations
                    : stations
                        .where((s) =>
                            s.name.toLowerCase().contains(_query))
                        .toList(),
              ),
          },
        ),
      ],
    );
  }
}

class _FavouritesGrid extends ConsumerWidget {
  final List<Station> stations;

  const _FavouritesGrid({required this.stations});

  void _play(BuildContext context, WidgetRef ref, Station station) {
    ref.read(playerNotifierProvider.notifier).playStation(station, stations);
    context.push(TvRoutes.player);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (stations.isEmpty) {
      return const Center(
        child: Text(
          'No results.',
          style: TextStyle(color: TvColors.onSurfaceVariant, fontSize: 18),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 48, right: 48, bottom: 24),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1,
        ),
        itemCount: stations.length,
        itemBuilder: (context, i) => _FavTile(
          station: stations[i],
          autofocus: false,
          onTap: () => _play(context, ref, stations[i]),
          onRemove: () => ref
              .read(favouritesTvNotifierProvider.notifier)
              .removeFavourite(stations[i].id),
        ),
      ),
    );
  }
}

/// Wraps TvStationTile and intercepts the Menu key for remove-action.
class _FavTile extends StatefulWidget {
  final Station station;
  final bool autofocus;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavTile({
    required this.station,
    required this.autofocus,
    required this.onTap,
    required this.onRemove,
  });

  @override
  State<_FavTile> createState() => _FavTileState();
}

class _FavTileState extends State<_FavTile> {
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlay;

  @override
  void dispose() {
    _overlay?.remove();
    _focusNode.dispose();
    super.dispose();
  }

  void _showRemoveMenu() {
    _overlay?.remove();
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    _overlay = OverlayEntry(
      builder: (_) => Positioned(
        left: offset.dx,
        top: offset.dy + box.size.height + 8,
        child: Material(
          color: TvColors.surface,
          borderRadius: BorderRadius.circular(8),
          elevation: 8,
          child: InkWell(
            onTap: () {
              _overlay?.remove();
              _overlay = null;
              widget.onRemove();
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                'Remove from favourites',
                style: TextStyle(color: TvColors.onSurface, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlay!);
    Future.delayed(const Duration(seconds: 3), () {
      _overlay?.remove();
      _overlay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.contextMenu): const _MenuIntent(),
      },
      child: Actions(
        actions: {
          _MenuIntent: CallbackAction<_MenuIntent>(
            onInvoke: (_) {
              _showRemoveMenu();
              return null;
            },
          ),
        },
        child: TvStationTile(
          station: widget.station,
          autofocus: widget.autofocus,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

class _MenuIntent extends Intent {
  const _MenuIntent();
}
