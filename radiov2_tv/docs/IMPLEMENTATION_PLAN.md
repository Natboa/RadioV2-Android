# RadioV2 TV — Implementation Plan

Android TV Flutter app. Shares the same bundled `stations.db` and all business logic
with the phone app. Only the UI layer is rebuilt from scratch for the 10-foot experience.

---

## Architecture Overview

```
radiov2_tv/
├── lib/
│   ├── core/               ← copied from phone app (do not diverge)
│   │   ├── audio/
│   │   ├── data/
│   │   ├── database/
│   │   ├── model/
│   │   └── providers.dart
│   ├── designsystem/
│   │   ├── tv_colors.dart       ← TV colour tokens (same accent #0097B2)
│   │   ├── tv_theme.dart        ← MaterialApp theme, overscan, large type
│   │   └── tv_focus.dart        ← focus decoration helpers
│   ├── navigation/
│   │   ├── tv_router.dart       ← go_router config
│   │   └── tv_destinations.dart ← route constants
│   ├── feature/
│   │   ├── home/           ← recently visited + featured stations
│   │   ├── discover/       ← category carousels (groups → stations)
│   │   ├── browse/         ← full station grid with letter jump
│   │   ├── favourites/     ← favourites grid
│   │   ├── player/         ← fullscreen now-playing overlay
│   │   └── settings/       ← import favourites + version
│   ├── shell/
│   │   └── tv_shell.dart   ← side rail + content area layout
│   ├── app.dart
│   └── main.dart
├── android/
├── assets/                 ← same db + images as phone app (symlink or copy)
└── docs/
    └── IMPLEMENTATION_PLAN.md
```

### Core layer strategy
Copy `lib/core/` from the phone app into `radiov2_tv/lib/core/` at the start of each
phase. The core is stable — it changes rarely. If a core fix is made in the phone app,
manually mirror it here. A full monorepo extraction is deferred until warranted.

---

## Key TV Constraints

| Constraint | Detail |
|---|---|
| **No touch** | All interaction via D-pad + OK + Back. No swipe, no long-press. |
| **Landscape only** | Lock to landscape in the manifest. |
| **Overscan safe area** | All content inset minimum 48 dp from screen edges. |
| **Focus ring** | Every focusable widget must show a visible focus highlight. |
| **Large text** | Base body 18 sp, titles 22–28 sp, headers 32 sp+. |
| **GestureDetector(onTap)** | Still fires on OK button — no need to replace with InkWell. |
| **Back button** | Android back = D-pad Back. go_router handles navigation automatically. |

---

## Phase 1 — Project Foundation

**Goal:** A blank TV app that boots, passes TV device checks, and shows a loading screen.

### 1.1 Android manifest
File: `android/app/src/main/AndroidManifest.xml`

```xml
<!-- Declare this as a TV app -->
<uses-feature android:name="android.software.leanback" android:required="true" />
<!-- Touch is not required on TV -->
<uses-feature android:name="android.hardware.touchscreen" android:required="false" />

<application android:banner="@drawable/tv_banner" ...>
  <activity ...>
    <intent-filter>
      <action android:name="android.intent.action.MAIN" />
      <category android:name="android.intent.category.LEANBACK_LAUNCHER" />
    </intent-filter>
  </activity>
</application>
```

- Add `android:banner` — a 320×180 px drawable used on the TV launcher row.
- Set `android:screenOrientation="landscape"` on the activity.
- `minSdkVersion 21` (Android TV minimum), target 34.

### 1.2 pubspec.yaml
Copy all dependencies from the phone app `pubspec.yaml`. Same versions.
Change `name: radiov2_tv`, `description: "RadioV2 TV"`.

Add assets block — copy or symlink `assets/database/stations.db` and `assets/images/`.

### 1.3 Core layer
Copy `lib/core/` verbatim from the phone app. Do not modify any files in this copy.
Verify `providers.dart` still compiles (no UI imports in core).

### 1.4 main.dart
Identical bootstrap to the phone app:
- `AudioService.init()`
- `SharedPreferences.getInstance()`
- `ProviderScope` with overrides
- `runApp(RadioV2TvApp())`

### 1.5 Smoke test
Run on an Android TV emulator (API 29+). Confirm the app launches and the loading
indicator appears. The TV launcher should show the app with a banner.

---

## Phase 2 — Design System

**Goal:** TV-specific colours, typography, theme, and a reusable focus decoration.

### 2.1 `tv_colors.dart`
Same accent (`#0097B2`) and background (`#121212`) as the phone app.
Add `tvFocusBorder` — a bright teal border used on focused widgets.

```dart
static const Color focusBorder = Color(0xFF0097B2);
static const Color focusOverlay = Color(0x1A0097B2); // 10% tint on focused tile
```

### 2.2 `tv_theme.dart`
- `MaterialApp` receives `theme` (dark) — TV is always dark.
- Base `fontSize` scale: body 18, bodyLarge 20, titleMedium 22, titleLarge 28, headlineMedium 32.
- `focusColor` and `hoverColor` set globally via `ThemeData`.
- `CardTheme` default elevation 0 — focus ring provides depth instead.

### 2.3 `tv_focus.dart`
A `TvFocusCard` widget:
- Wraps any child with a `Focus` widget.
- On focus: draws a 2 dp teal border + slight scale (1.05) using `AnimatedScale` +
  `AnimatedContainer`.
- On unfocus: no border, scale 1.0.
- Forwards `onTap` callback (fires on OK button).

```dart
class TvFocusCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool autofocus;
}
```

This is the single building block used for every interactive element in the app.

---

## Phase 3 — Navigation Shell

**Goal:** A side navigation rail on the left with 5 destinations. Content fills the right.

### 3.1 Layout

```
┌────────────────────────────────────────────────┐
│  Rail │                Content                  │
│  72dp │                                         │
│       │                                         │
│  icon │                                         │
│  icon │                                         │
│  icon │                                         │
│  icon │                                         │
│       │                                         │
└────────────────────────────────────────────────┘
```

The rail is always visible (not a drawer). Width: 72 dp icon-only, no labels
(labels appear as tooltips on focus).

### 3.2 `tv_shell.dart`

Use `StatefulShellRoute.indexedStack` in go_router with a `Row` shell widget:

```dart
Row(
  children: [
    TvSideRail(currentIndex: shell.currentIndex, onSelect: shell.goBranch),
    Expanded(child: shell),
  ],
)
```

`TvSideRail` destinations:
- Home (`Icons.home`)
- Discover (`Icons.explore`)
- Browse (`Icons.radio`)
- Favourites (`Icons.favorite`)
- Settings (`Icons.settings`)

Each rail item is a `TvFocusCard` with an icon. Focused + selected states are distinct:
selected = filled icon + accent colour; focused = focus ring.

### 3.3 `tv_router.dart`
go_router with `StatefulShellRoute.indexedStack`. Routes:

| Path | Screen |
|---|---|
| `/home` | HomeScreen |
| `/discover` | DiscoverScreen |
| `/discover/group/:groupId` | GroupDetailScreen |
| `/browse` | BrowseScreen |
| `/favourites` | FavouritesScreen |
| `/settings` | SettingsScreen |

Initial location: `/home`.

### 3.4 Focus traversal between rail and content
The rail and content area are separate `FocusTraversalGroup` zones. D-pad left from
the first content column focuses the rail; D-pad right from the rail focuses the
first item in content.

---

## Phase 4 — Home Screen

**Goal:** A "continue listening" row + a featured stations row. Good landing page on a TV.

### Layout

```
┌────────────────────────────────────┐
│  Recently Visited                  │
│  [tile] [tile] [tile] ...          │
│                                    │
│  Featured                          │
│  [tile] [tile] [tile] ...          │
└────────────────────────────────────┘
```

### Data sources
- **Recently visited**: `RecentlyVisitedNotifier` from core (already persistent via SharedPreferences — max 10 entries).
- **Featured**: `StationRepository.getFeaturedStations()` (uses `isFeatured` column).

### Tile design (`TvStationTile`)
- 180×180 dp square.
- Station logo fills the tile; fallback = radio icon on surfaceVariant background.
- Station name overlaid at bottom with a dark gradient scrim.
- `TvFocusCard` wrapper.

### Notifier / state
`HomeNotifier extends Notifier<HomeUiState>` — loads both lists in parallel via
`Future.wait`. Standard `loading / success / error` sealed state.

---

## Phase 5 — Discover Screen

**Goal:** Category rows with horizontal carousels of group cards, navigable by D-pad.

The phone app's `_CategoriesList` is already a vertical list of horizontal rows —
exactly the correct TV pattern. Adapt it:

- Increase group card size to ~220×220 dp.
- Remove the search bar (TV keyboards are painful — defer search to a later phase or omit).
- Each row is a `ListView` with `scrollDirection: Axis.horizontal`.
- Focus moves vertically between rows and horizontally within a row.
- Use `ScrollController` to auto-scroll the focused item into view.

### Group Detail Screen
When a group card is selected (OK), navigate to `/discover/group/:groupId`.
Layout: title bar + vertical `ListView` of `TvStationTile` rows (station name + logo).
Selecting a station starts playback and opens the Player overlay.

---

## Phase 6 — Browse Screen

**Goal:** All stations in a scrollable grid, sorted alphabetically.

- `GridView` with 4 columns.
- Each cell: `TvStationTile`.
- `StationRepository.getStationsPaginated()` — load 50 at a time, append on scroll.
- No search in MVP (same as Discover — omit for now).

---

## Phase 7 — Favourites Screen

**Goal:** Saved stations in a grid with a quick-remove action.

- Same `GridView` layout as Browse (4 columns).
- Tiles: `TvStationTile`.
- Long-press equivalent: a secondary action triggered by the **Menu** button
  (Android TV remote has a menu/options button) — shows a small overlay with
  "Remove from favourites". Use `Shortcuts` + `Actions` for this.
- Empty state: centred icon + "No favourites yet".
- Data: `FavouriteRepository.watchFavouriteStations()` stream.

---

## Phase 8 — Player (Now Playing Overlay)

**Goal:** Fullscreen now-playing experience triggered when any station is selected.

The player is a fullscreen overlay pushed on top of the current screen (not a
separate route in the shell). Use `showGeneralDialog` or a dedicated route outside
the shell: `/player`.

### Layout (landscape fullscreen)

```
┌────────────────────────────────────────────────┐
│  [←back]                    [♥ favourite]      │
│                                                 │
│   ┌──────────┐    Station Name                 │
│   │  Artwork │    ICY now-playing text          │
│   │  240×240 │                                 │
│   └──────────┘    [⏮]  [▶/⏸]  [⏭]           │
│                                                 │
└────────────────────────────────────────────────┘
```

- Artwork on the left, info + controls on the right.
- Buffering state: spinner over artwork.
- Error state: wifi-off icon + red accent on play button.
- Controls are `TvFocusCard` wrapped `IconButton`s — D-pad navigates between them.
- Back button (D-pad Back) closes the overlay and returns to the previous screen.
- `playerNotifierProvider` is `keepAlive: true` — playback continues when overlay is dismissed.

### Activation
Any `TvStationTile.onTap` calls `playerNotifier.play(station)` then
`context.push(TvRoutes.player)`.

---

## Phase 9 — Settings Screen

**Goal:** Import favourites (M3U) and app version display. Mirror the phone app feature set.

- Single column list.
- **Import favourites** tile → file picker → M3U import via `SettingsNotifier` (copy from phone app verbatim).
- **App version** tile (read-only).
- No export (TV has no share sheet). Import only.

---

## Phase 10 — Focus Polish & Release

**Goal:** Verify full D-pad navigation with no dead ends or focus traps.

### Checklist
- [ ] Every screen has an `autofocus` widget so the remote works immediately on arrival.
- [ ] All `ListView` / `GridView` items auto-scroll focused item into view
      (`Scrollable.ensureVisible` or `ScrollController`).
- [ ] Back button on every screen either goes back or closes the app cleanly.
- [ ] Player overlay dismisses correctly; mini-player equivalent not needed (TV stays fullscreen).
- [ ] Rail focus is reachable from every screen via D-pad left.
- [ ] No `GestureDetector` with touch-only gestures (swipe, drag) present anywhere.
- [ ] Overscan: all text and interactive elements are at least 48 dp from screen edges.

### Release build
```bash
cd radiov2_tv
flutter build apk --release
```

Output APK: `build/app/outputs/flutter-apk/app-release.apk`

Sideload via ADB for testing on a physical TV or Fire Stick:
```bash
adb connect <tv-ip>:5555
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Dependencies (additions over phone app)

No new packages required. All dependencies already present in the phone app's
`pubspec.yaml` cover the TV app's needs.

---

## What is NOT in MVP

- Search (requires on-screen keyboard — poor TV UX)
- Export favourites (no share sheet on TV)
- Recently visited on Home if empty (gracefully hide the section)
- Custom launcher banner art (placeholder acceptable for now)
