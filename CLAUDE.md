# RadioV2 Android — Claude Guidelines

## Project
Flutter Android app (radio stations, Spotify-like UX). Dark theme, accent `#0097B2`.  
Plan: `IMPLEMENTATION_PLAN.md`. Features spec: `APP_FEATURES.md`.

## Stack
- **Flutter** 3.22+ / Dart 3.4+, Android-only (min API 26)
- **State:** Riverpod 2.5 + riverpod_annotation (code-gen, always run build_runner after changes)
- **Database:** Drift 2.18 — bundled `Data/stations.db` copied to documents on first launch
- **Audio:** just_audio + audio_service (background playback, notification controls)
- **Navigation:** go_router with `StatefulShellRoute.indexedStack`
- **Debugging:** VS Code Flutter extension (breakpoints, hot reload/restart)

## Architecture Rules
- Follow clean architecture: `core/` (database, models, repositories, audio, designsystem) + `feature/` (browse, discover, favourites, player)
- Every feature has: `*_screen.dart`, `*_notifier.dart` (Riverpod Notifier), `*_state.dart` (sealed UiState)
- UiState always has: `loading`, `success`, `error` variants minimum
- Repositories are interfaces with `_impl` implementations — never access DAOs directly from notifiers
- `keepAlive: true` on providers that must survive tab switches: player, categories, db, repositories
- Never write to `isFavorite` on StationTable — user favourites live in `FavouriteTable` only

## Key Files
- `lib/main.dart` — bootstrap order matters: DB init → AudioService.init → ProviderScope
- `lib/core/audio/audio_service_handler.dart` — RadioAudioHandler (wraps just_audio)
- `lib/feature/player/player_notifier.dart` — global playback state, keepAlive
- `lib/navigation/app_router.dart` — all routes defined here

## Skills to Use
- **`claude-android-skill-main/`** — reference for architecture patterns, adapt Kotlin/Hilt/Room examples to Flutter/Riverpod/Drift equivalents (see mapping table in IMPLEMENTATION_PLAN.md)

## Memory (claude-mem)
This project uses [claude-mem](https://github.com/thedotmack/claude-mem) for persistent memory across sessions.  
It auto-captures tool usage, generates summaries, and injects relevant context into future conversations.

**First-time setup** (run once in the Claude Code terminal):
```
/plugin marketplace add thedotmack/claude-mem
/plugin install claude-mem
```
Then restart Claude Code. After that, previous session context is injected automatically.  
Search past context with `/mem-search <query>` during any session.

## Conventions
- Run `flutter pub run build_runner build --delete-conflicting-outputs` after any Riverpod or Drift annotation changes
- Group PNG assets map by exact group name: `assets/images/groups/<GroupName>.png`
- No import/export in MVP — don't add it
- Dark theme only — no system theme switching
- Pagination page size: 50 for Browse, 30 for Group Detail
- Search debounce: 300ms
