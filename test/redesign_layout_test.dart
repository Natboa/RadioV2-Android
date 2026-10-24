import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:radiov2_android/app.dart';
import 'package:radiov2_android/core/designsystem/theme.dart';
import 'package:radiov2_android/core/data/repository/favourite_repository.dart';
import 'package:radiov2_android/core/model/station.dart';
import 'package:radiov2_android/core/model/group.dart';
import 'package:radiov2_android/core/model/category.dart';
import 'package:radiov2_android/core/providers.dart';
import 'package:radiov2_android/core/ui/widgets/group_card.dart';
import 'package:radiov2_android/core/ui/widgets/station_list_item.dart';
import 'package:radiov2_android/core/ui/widgets/station_logo.dart';
import 'package:radiov2_android/feature/discover/discover_screen.dart';
import 'package:radiov2_android/feature/discover/discover_notifier.dart';
import 'package:radiov2_android/feature/discover/discover_state.dart';
import 'package:radiov2_android/feature/player/player_notifier.dart';
import 'package:radiov2_android/feature/player/player_state.dart';
import 'package:radiov2_android/feature/player/player_controls.dart';
import 'package:radiov2_android/feature/player/mini_player.dart';
import 'package:radiov2_android/feature/player/now_playing_screen.dart';
import 'package:radiov2_android/feature/settings/settings_notifier.dart';
import 'package:radiov2_android/feature/settings/settings_state.dart';

class _Player extends StateNotifier<PlayerUiState> implements PlayerNotifier {
  _Player(super.state);
  @override
  Future<void> playPause() async =>
      state = state.copyWith(isPlaying: !state.isPlaying);
  @override
  Future<void> stop() async => state = const PlayerUiState();
  @override
  Future<void> toggleFavourite(int id) async =>
      state = state.copyWith(isFavourite: !state.isFavourite);
  @override
  Future<void> nextStation() async {}
  @override
  Future<void> previousStation() async {}
  @override
  Future<void> playStation(Station station, List<Station> playlist) async {}
}

class _Favourites extends Fake implements FavouriteRepository {
  @override
  Stream<bool> watchIsFavourite(int id) => Stream.value(true);
  @override
  Stream<List<Station>> watchFavourites() => Stream.value([]);
}

class _Discover extends StateNotifier<DiscoverUiState>
    implements DiscoverNotifier {
  _Discover(super.state);
  @override
  void setQuery(String query) {}
  @override
  Future<void> retry() async {}
}

class _Settings extends StateNotifier<SettingsUiState>
    implements SettingsNotifier {
  _Settings() : super(const SettingsIdle());
  @override
  void reset() => state = const SettingsIdle();
  @override
  Future<void> importFavourites() async {}
  @override
  Future<void> exportFavourites() async {}
}

const _station = Station(
    id: 1,
    name:
        'A very long station name with Unicode 東京, العربية and an unbroken_identifier_12345678901234567890',
    streamUrl: 'https://test.invalid',
    groupId: 1);

Future<void> _size(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _host(Widget child,
        {PlayerUiState state = const PlayerUiState(),
        double scale = 1,
        Brightness brightness = Brightness.light}) =>
    ProviderScope(
      overrides: [
        playerNotifierProvider.overrideWith((_) => _Player(state)),
        favouriteRepositoryProvider.overrideWithValue(_Favourites())
      ],
      child: MaterialApp(
          theme: buildRadioV2Theme(brightness: brightness),
          home: MediaQuery(
              data: MediaQueryData(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true),
              child: child)),
    );

void main() {
  testWidgets('missing artwork uses a readable theme-aware station monogram',
      (tester) async {
    await tester.pumpWidget(_host(const Scaffold(
        body: StationLogo(size: 48, stationName: 'Burina.NET Demo Radio'))));
    await tester.pumpAndSettle();
    expect(find.text('BD'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('the actual app boots into the system-themed library',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      playerNotifierProvider
          .overrideWith((_) => _Player(const PlayerUiState())),
      favouriteRepositoryProvider.overrideWithValue(_Favourites()),
    ], child: const RadioV2App()));
    await tester.pumpAndSettle();
    expect(find.text('A place for your favourites'), findsOneWidget);
    expect(
        Theme.of(tester.element(find.text('A place for your favourites')))
            .brightness,
        Brightness.dark);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Discover constructs only visible shelves and group cards',
      (tester) async {
    await _size(tester, const Size(390, 844));
    final categories = List.generate(
        40,
        (i) => CategoryWithGroups(
            category: Category(id: i, name: 'Category $i', displayOrder: i),
            groups:
                List.generate(50, (j) => Group(id: i * 50 + j, name: 'Jazz'))));
    await tester.pumpWidget(ProviderScope(
        overrides: [
          discoverNotifierProvider
              .overrideWith((_) => _Discover(DiscoverSuccess(categories)))
        ],
        child: MaterialApp(
            theme: buildRadioV2Theme(), home: const DiscoverScreen())));
    await tester.pumpAndSettle();
    expect(find.byType(GroupCard).evaluate().length, lessThan(25));
    expect(find.text('Category 39'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('opening a collection does not restore search focus on Back',
      (tester) async {
    final router = GoRouter(initialLocation: '/discover', routes: [
      GoRoute(
          path: '/discover',
          builder: (_, __) => const DiscoverScreen(),
          routes: [
            GoRoute(
                path: 'group/:id',
                builder: (_, __) => const Scaffold(body: Text('Collection'))),
          ]),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(overrides: [
      discoverNotifierProvider.overrideWith((_) => _Discover(DiscoverSuccess([
            CategoryWithGroups(
                category:
                    const Category(id: 1, name: 'Genres', displayOrder: 1),
                groups: [const Group(id: 1, name: 'Jazz')]),
          ]))),
    ], child: MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'jazz');
    await tester.pump();
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    await tester.tap(find.byType(GroupCard));
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isFalse,
        reason:
            'Back should return to browsing without reopening the keyboard.');
  });
  testWidgets(
      'appearance switches through the actual settings route at large text',
      (tester) async {
    await _size(tester, const Size(390, 844));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      playerNotifierProvider
          .overrideWith((_) => _Player(const PlayerUiState())),
      favouriteRepositoryProvider.overrideWithValue(_Favourites()),
      settingsNotifierProvider.overrideWith((_) => _Settings()),
    ], child: const RadioV2App()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('Appearance'))).brightness,
        Brightness.dark);
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('Appearance'))).brightness,
        Brightness.light);
    expect(prefs.getString('appearance'), 'light');
    expect(tester.takeException(), isNull);
  });
  for (final size in [const Size(320, 568), const Size(800, 600)]) {
    for (final brightness in Brightness.values) {
      testWidgets(
          'player handles $size, $brightness, large text and offline state',
          (tester) async {
        await _size(tester, size);
        await tester.pumpWidget(_host(const NowPlayingScreen(),
            scale: 2,
            brightness: brightness,
            state: const PlayerUiState(
                station: _station, playlist: [_station], isError: true)));
        await tester.pumpAndSettle();
        expect(find.text('Station unavailable'), findsOneWidget);
        expect(find.byTooltip('Retry station'), findsOneWidget);
        expect(tester.getBottomRight(find.byTooltip('Retry station')).dy,
            lessThanOrEqualTo(size.height),
            reason: 'Playback recovery must stay reachable without scrolling.');
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('mini-player leaves readable title at 320dp and 200 percent text',
      (tester) async {
    await _size(tester, const Size(320, 568));
    await tester.pumpWidget(_host(
        const Scaffold(bottomNavigationBar: MiniPlayerBar()),
        scale: 2,
        state: const PlayerUiState(station: _station)));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Play'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('play pause feedback reverses and settles with reduced motion',
      (tester) async {
    await tester.pumpWidget(_host(const Scaffold(body: _LiveButton()),
        state: const PlayerUiState(station: _station)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Play'));
    await tester.pump();
    expect(find.byTooltip('Pause'), findsOneWidget);
    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Play'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
  });
  testWidgets('saved hearts use foreground and expose a removal action',
      (tester) async {
    await tester.pumpWidget(_host(Scaffold(
        body: StationListItem(
            station: _station,
            isSelected: true,
            isPlaying: true,
            onTap: () {},
            onFavouriteTap: () {}))));
    await tester.pumpAndSettle();
    final icon = tester.widget<Icon>(find.byIcon(Icons.favorite_rounded));
    final context = tester.element(find.byType(StationListItem));
    expect(icon.color, Theme.of(context).colorScheme.onSurface);
    expect(find.byTooltip('Remove from favourites'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _LiveButton extends ConsumerWidget {
  const _LiveButton();
  @override
  Widget build(BuildContext context, WidgetRef ref) => PlayPauseButton(
      state: ref.watch(playerNotifierProvider),
      onPressed: ref.read(playerNotifierProvider.notifier).playPause);
}
