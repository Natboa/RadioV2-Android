# RadioV2 Android — Flutter Implementation Plan

## Context

RadioV2 is an internet radio app modelled after Spotify's UX. A fully-featured Windows WPF desktop version already exists with a 79 MB SQLite database (~tens of thousands of stations), 124 genre/country PNG assets, and a complete feature set. This plan builds the Android companion app in Flutter — chosen over native Kotlin because the user explicitly wants Flutter, and it allows future iOS expansion with the same codebase. The architectural patterns from the Android skill docs (`claude-android-skill-main/`) are adapted to Flutter/Riverpod idioms.

**MVP scope:** Browse + search, Discover (11 category carousels), Favourites, persistent Mini Player. No import/export in v1.

---

## Tech Stack

| Concern | Choice | Rationale |
|---|---|---|
| Framework | Flutter 3.22+ / Dart 3.4+ | User's explicit choice; future iOS portability |
| State management | Riverpod 2.5 + riverpod_annotation | Closest Flutter equivalent to MVVM + Notifier pattern from skill docs |
| Database | Drift 2.18 + drift_flutter | Reactive `Stream<T>` queries (mirrors Room + Flow); type-safe DAOs |
| Audio | just_audio 0.9.39 + audio_service 0.18.13 | Industry-standard Flutter background audio pair |
| Navigation | go_router 14 | `StatefulShellRoute.indexedStack` preserves per-tab scroll state |
| Images | cached_network_image 3.3 | Station logo loading with disk cache |
| Min Android | API 26 (Android 8.0+) | Covers ~95% devices; required for modern audio/notification APIs |

---

## Project Structure

```
c:\VS Code repos\RadioV2 Android\
├── android/
│   └── app/src/main/AndroidManifest.xml   ← permissions, AudioService declaration
├── assets/
│   ├── database/stations.db               ← copy from radioV2/Data/stations.db
│   └── images/
│       ├── groups/                         ← 124 PNGs from Images/Groups/
│       └── logo/                           ← app logo PNGs
└── lib/
    ├── main.dart                           ← bootstrap: DB init, AudioService.init, ProviderScope
    ├── app.dart                            ← MaterialApp.router, theme, go_router
    ├── core/
    │   ├── database/
    │   │   ├── app_database.dart           ← @DriftDatabase class
    │   │   ├── tables/                     ← station_table, group_table, category_table, favourite_table
    │   │   └── daos/                       ← station_dao, group_dao, category_dao, favourite_dao
    │   ├── model/                          ← pure Dart: Station, Group, Category, CategoryWithGroups, GroupWithCount, PlayerState
    │   ├── data/
    │   │   ├── datasource/database_initializer.dart   ← asset → documents copy on first launch
    │   │   └── repository/                 ← StationRepository (interface + impl), FavouriteRepository (interface + impl)
    │   ├── audio/
    │   │   ├── audio_service_handler.dart  ← RadioAudioHandler extends BaseAudioHandler
    │   │   └── now_playing_parser.dart     ← port of WPF NowPlayingParser
    │   ├── designsystem/
    │   │   ├── colors.dart                 ← RadioV2Colors constants
    │   │   └── theme.dart                  ← buildRadioV2Theme() dark Material 3
    │   └── ui/widgets/
    │       ├── station_list_item.dart      ← shared station row widget
    │       ├── group_card.dart             ← 120×160 card with PNG art
    │       └── favourite_button.dart       ← heart icon toggle
    ├── feature/
    │   ├── browse/
    │   │   ├── browse_screen.dart          ← BrowseRoute + BrowseScreen
    │   │   ├── browse_notifier.dart        ← AsyncNotifier with search debounce + pagination
    │   │   └── browse_state.dart           ← sealed BrowseUiState
    │   ├── discover/
    │   │   ├── discover_screen.dart        ← category carousels with sticky headers
    │   │   ├── discover_notifier.dart      ← keepAlive, loads once
    │   │   ├── discover_state.dart
    │   │   └── group_detail/
    │   │       ├── group_detail_screen.dart
    │   │       ├── group_detail_notifier.dart
    │   │       └── group_detail_state.dart
    │   ├── favourites/
    │   │   ├── favourites_screen.dart
    │   │   ├── favourites_notifier.dart    ← reactive stream from FavouriteRepository
    │   │   └── favourites_state.dart
    │   └── player/
    │       ├── mini_player.dart            ← MiniPlayerBar widget (72dp height)
    │       ├── player_notifier.dart        ← keepAlive; drives all playback + reconnect
    │       └── player_state.dart           ← sealed PlayerUiState (idle / active)
    └── navigation/
        ├── app_router.dart                 ← StatefulShellRoute.indexedStack, 3 branches
        └── app_destinations.dart           ← route constants, AppDestination enum
```

---

## Key pubspec.yaml Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  go_router: ^14.2.7
  drift: ^2.18.0
  drift_flutter: ^0.2.1
  sqlite3_flutter_libs: ^0.5.24
  just_audio: ^0.9.39
  audio_service: ^0.18.13
  audio_session: ^0.1.21
  cached_network_image: ^3.3.1
  connectivity_plus: ^6.0.3
  path_provider: ^2.1.3
  path: ^1.9.0
  shared_preferences: ^2.2.3

dev_dependencies:
  build_runner: ^2.4.11
  riverpod_generator: ^2.4.3
  drift_dev: ^2.18.0
```

---

## Database Design

The 79 MB `stations.db` is bundled as a Flutter asset and copied to the app's documents directory on first launch (read-only assets can't be queried directly). Drift maps to the existing schema — no migrations needed; the DB is pre-populated.

**Existing schema (unchanged):**
- `Station` — id, name, streamUrl, logoUrl, groupId, isFavorite, isFeatured
- `Group` — id, name, categoryId
- `Category` — id, name, displayOrder
- `Favourite` — id, stationId ← user's live favourites (write here, not to `isFavorite`)

**Key queries (StationDao):**
- `searchStations(query, offset, limit)` → paginated filtered search
- `getStationsByGroup(groupId, offset, limit, [query])` → group detail list
- `getFeaturedByGroup(groupId)` → featured stations for group header
- `watchFavourites()` → `Stream<List<Station>>` with JOIN (reactive updates)

---

## Architecture Patterns (from skill docs, adapted for Flutter)

| Android Skill Doc Pattern | Flutter Equivalent |
|---|---|
| `@HiltViewModel` | `@riverpod class XNotifier extends _$XNotifier` |
| `StateFlow<UiState>` | `NotifierProvider` / `AsyncNotifierProvider` |
| `@Singleton` | `@Riverpod(keepAlive: true)` |
| `Room DAO + Flow<List<T>>` | `Drift DAO + Stream<List<T>>` (`.watch()`) |
| `collectAsStateWithLifecycle()` | `ref.watch(provider)` |
| Sealed `UiState` | Dart `sealed class` with factory constructors |
| Route-Screen split | `XRoute (ConsumerWidget)` wrapping stateless `XScreen` |

All `UiState` types use `sealed class` with `loading / success / error / empty` variants — matching the skill docs' pattern exactly.

---

## Audio Architecture

```
main.dart
  └─ AudioService.init(RadioAudioHandler)   ← must happen before runApp
  └─ ProviderScope(overrides: [audioHandlerProvider, appDatabaseProvider])

RadioAudioHandler extends BaseAudioHandler
  ├─ AudioPlayer (_player)                  ← just_audio engine
  ├─ playUrl(url)                           ← custom command
  ├─ play / pause / stop overrides
  ├─ playbackEventStream → playbackState broadcast (drives notification)
  └─ icyMetadataStream → StreamController → PlayerNotifier (now-playing text)

PlayerNotifier (keepAlive: true)
  ├─ playStation(station, playlist)         ← calls handler.playUrl
  ├─ playPause / stop / nextStation / previousStation
  ├─ toggleFavourite                        ← delegates to FavouriteRepository
  ├─ listens to playbackState              ← updates isPlaying / isBuffering
  ├─ listens to icyMetadata stream         ← updates nowPlayingArtist / Title
  └─ listens to connectivity_plus          ← auto-reconnect on network restore
```

**AndroidManifest.xml requirements:**
- `INTERNET`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`
- `<service>` declaration for `AudioService`
- `android:usesCleartextTraffic="true"` (many radio streams are HTTP)
- `android:launchMode="singleTask"` (prevents duplicate Activity on notification tap)

---

## UI Layout

**App shell** (`AppScaffold`):
```
Scaffold
  body: navigationShell (go_router StatefulShellRoute)
  bottomNavigationBar: Column(
    MiniPlayerBar (hidden when PlayerUiState.idle)
    NavigationBar (Browse | Discover | Favourites)
  )
```

**Mini Player** (72dp, teal top border):
```
Row: [StationLogo 48dp] [Name + NowPlaying text] [Prev] [Play/Pause|Spinner] [Next] [Heart]
```

**Discover screen**: `CustomScrollView` with `SliverList` of sticky category headers, each followed by a horizontal `ListView.builder` carousel of `GroupCard` widgets.

**GroupCard**: 120×160dp, PNG art from `assets/images/groups/<GroupName>.png`, name + station count label below.

**Theme**: Dark-only Material 3, accent `#0097B2` (teal-blue), background `#121212`, surface `#1E1E1E`.

---

## Implementation Order

**Phase 1 — Bootstrap** (Day 1)
1. `flutter create radiov2_android --platforms=android`
2. Set `minSdkVersion 26` in `android/app/build.gradle`
3. Add all `pubspec.yaml` dependencies, copy assets (`stations.db`, 124 PNGs)
4. Create full `lib/` folder skeleton with empty files
5. Verify `flutter build apk --debug` compiles

**Phase 2 — Theme** (Day 1–2)
6. `colors.dart`, `theme.dart`, `app.dart` with dark MaterialApp shell
7. Placeholder screens with hot-reload verification

**Phase 3 — Database Layer** (Day 2–3)
8. Drift `Table` classes (mirror existing schema)
9. `AppDatabase` + `DatabaseInitializer` (asset copy logic)
10. All four DAOs with required queries
11. `flutter pub run build_runner build`
12. Temp debug screen reading 5 stations — verify DB works

**Phase 4 — Repositories + Providers** (Day 3–4)
13. Domain model classes + Drift row → domain mappers
14. `StationRepositoryImpl` + `FavouriteRepositoryImpl`
15. Core Riverpod providers (`appDatabaseProvider`, `stationRepositoryProvider`, `favouriteRepositoryProvider`)
16. Build runner

**Phase 5 — Navigation Shell** (Day 4)
17. `app_router.dart` with `StatefulShellRoute.indexedStack`
18. `AppScaffold` with `NavigationBar`, stub screens
19. Verify tab switching and back-stack

**Phase 6 — Browse** (Day 5–6)
20. `BrowseUiState` sealed class
21. `BrowseNotifier` (paginated load, 300ms search debounce)
22. `StationListItem` shared widget
23. `BrowseScreen` with search bar + lazy paginated list

**Phase 7 — Discover** (Day 6–8)
24. `DiscoverCategoriesNotifier` (keepAlive, loads once)
25. `GroupCard` widget (PNG art mapping by group name)
26. `DiscoverScreen` with sticky-header carousels
27. `GroupDetailNotifier` + `GroupDetailScreen` (featured section + paginated list)
28. Navigation: GroupCard → GroupDetail route

**Phase 8 — Favourites** (Day 8–9)
29. `FavouritesNotifier` using `watchFavourites()` reactive stream
30. `FavouritesScreen` with empty state
31. Wire `toggleFavourite` across all screens through shared `FavouriteRepository`

**Phase 9 — Audio Service** (Day 9–11)
32. `AndroidManifest.xml` permissions + service declaration
33. `RadioAudioHandler` (just_audio + audio_service integration)
34. `NowPlayingParser.parse()` (port from WPF `NowPlayingParser`)
35. `PlayerNotifier` (playback, metadata, connectivity, next/prev)
36. `main.dart` bootstrap sequence (DB init → AudioService.init → ProviderScope)
37. Verify: playback, notification controls, lock-screen controls

**Phase 10 — Mini Player** (Day 11–12)
38. `MiniPlayerBar` widget
39. Integrate into `AppScaffold.bottomNavigationBar` Column
40. Wire Prev/Next with playlist context from active tab

**Phase 11 — Polish** (Day 12–14)
41. Loading skeletons / shimmer on initial DB load
42. Error states with retry buttons on all screens
43. Auto-reconnect test (airplane mode toggle)
44. Persist last-played station + volume in `SharedPreferences`
45. Fallback placeholder for missing group PNGs
46. `android:launchMode="singleTask"`, ProGuard rules for Drift + audio_service
47. `flutter build apk --release` smoke test

---

## Verification

- **Database**: Temp debug screen reads 5 stations on cold launch → confirms 79 MB asset copy works
- **Browse**: Type in search bar → list filters within 300ms; scroll to bottom → more stations load
- **Discover**: 11 categories visible; tap group card → group detail with featured section
- **Favourites**: Toggle heart on any screen → station appears/disappears in Favourites tab reactively
- **Audio**: Tap station → playback starts, mini player appears; lock screen shows notification with controls; background switch → audio continues; airplane mode off → auto-reconnects
- **Theme**: Dark background `#121212`, accent `#0097B2` on active nav item and play button
- **Assets**: All 124 group PNG images load in carousel cards; missing images show placeholder
