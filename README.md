<p align="center">
  <img src="assets/images/logo/radiov2_Logo_full.png" alt="RadioV2 Logo" width="320"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.0.0-blue?style=flat-square" alt="Version"/>
  <img src="https://img.shields.io/badge/platform-Android%208%2B-3DDC84?style=flat-square&logo=android&logoColor=white" alt="Platform"/>
  <img src="https://img.shields.io/badge/built%20with-Flutter-54C5F8?style=flat-square&logo=flutter&logoColor=white" alt="Flutter"/>
</p>

<h3 align="center">A modern Android internet radio player with a Spotify-inspired dark UI.</h3>

<!-- Screenshots go here -->

## Overview

RadioV2 Android is the mobile companion to the RadioV2 desktop app. It lets you discover, browse, and stream tens of thousands of internet radio stations organized by genre and country, with full background playback and lock-screen controls.

## Features

- Browse stations with live search and persistent recently visited history
- Discover stations by category with horizontal genre rows
- Search stations within any genre group
- Save and manage favourite stations (persisted across restarts and updates)
- Mini player bar always visible across all screens
- Background playback — music keeps playing when the app is minimized or the screen is off
- Media notification with artwork, play/pause, next, and previous controls
- Lock screen controls
- Animated equalizer bars on the currently playing station
- Dark theme

## Installation

**Option 1 — Install APK directly**

Download the latest release APK and install it on your Android device (Android 8.0 or higher):

👉 [app-release.apk](https://github.com/Natboa/RadioV2-Android/releases)

> Enable *Install from unknown sources* in your device settings if prompted.

**Option 2 — Build from source**

**Prerequisites:** Flutter 3.22+, Android SDK (min API 26).

```bash
git clone https://github.com/Natboa/RadioV2-Android.git
cd "RadioV2 Android"
flutter pub get
flutter run                   # debug on connected device
flutter build apk --release   # release APK
```

The release APK will be at `build/app/outputs/apk/release/app-release.apk`.

## Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter 3.22+ / Dart 3.4+ |
| State Management | Riverpod 2.5 + riverpod_annotation (code-gen) |
| Audio Playback | just_audio + audio_service |
| Database | Drift 2.18 (SQLite) — bundled station database |
| Navigation | go_router with indexed tab stack |
| Image Caching | cached_network_image + flutter_cache_manager |
| Persistence | SharedPreferences (history) + SQLite FavouriteTable |
| Target Platform | Android 8.0+ (API 26+) |

## Project Structure

```
lib/
├── core/
│   ├── audio/              # RadioAudioHandler (wraps just_audio + audio_service)
│   ├── data/
│   │   ├── datasource/     # DatabaseInitializer — copies bundled DB on first launch
│   │   └── repository/     # StationRepository, FavouriteRepository (interface + impl)
│   ├── database/           # Drift AppDatabase, DAOs, table definitions
│   ├── designsystem/       # Colors, theme
│   ├── model/              # Station, Group, Category
│   ├── ui/widgets/         # StationListItem, GroupCard, SoundBars, MiniPlayer
│   ├── providers.dart      # Core Riverpod providers
│   └── recently_visited_notifier.dart
├── feature/
│   ├── browse/             # Browse screen — search + recently visited
│   ├── discover/           # Discover screen — categories, groups, group detail
│   ├── favourites/         # Favourites screen
│   └── player/             # PlayerNotifier, PlayerState, NowPlaying screen
├── navigation/             # go_router route definitions
└── main.dart               # Bootstrap: AudioService + SharedPreferences + ProviderScope
```

## Legal

RadioV2 Android is an internet radio aggregator and does not host or rebroadcast audio content. All streams are provided by third-party radio stations and accessed directly by users.
