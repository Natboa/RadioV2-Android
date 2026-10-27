<p align="center">
  <img src="assets/images/logo/radiov2_Logo_full.png" alt="RadioV2 Logo" width="320"/>
</p>

<p align="center">
  <a href="https://github.com/Natboa/RadioV2-Android/releases"><img src="https://img.shields.io/badge/version-1.0.8-blue?style=flat-square" alt="Version"/></a>
  <a href="https://github.com/Natboa/RadioV2-Android/releases"><img src="https://img.shields.io/badge/platform-Android%208%2B-3DDC84?style=flat-square&logo=android&logoColor=white" alt="Android"/></a>
  <a href="https://github.com/Natboa/RadioV2-Android/releases"><img src="https://img.shields.io/badge/platform-Android%20TV-3DDC84?style=flat-square&logo=androidtv&logoColor=white" alt="Android TV"/></a>
  <img src="https://img.shields.io/badge/built%20with-Flutter-54C5F8?style=flat-square&logo=flutter&logoColor=white" alt="Flutter"/>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License"/></a>
</p>

<h3 align="center">A modern Android internet radio player with light and dark themes.</h3>

<p align="center">
  <img src="https://img.shields.io/badge/Also%20available%20on-Windows-0078D4?style=for-the-badge&logo=windows&logoColor=white" alt="Available on Windows"/>
</p>

<p align="center">
  <img src="assets/images/screenshots/radio-banner.png" alt="RadioV2 for Android: Discover countries, station browsing, Discover genres, and Favourites displayed on four black phones against a purple studio background." width="100%"/>
</p>

<p align="center">
  <img src="assets/images/logo/android_auto.png" alt="Android Auto" width="64"/>
  &nbsp;&nbsp;
  <strong>Supports Android Auto</strong>
</p>

<p align="center">
  <img src="assets/images/logo/android_tv.png" alt="Android TV" width="680"/>
  <br/>
  <strong>Supports Android TV</strong>
</p>

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
- Clear playback states and interruptible player transitions that respect reduced motion
- Android Auto support — browse favourites and control playback from your car
- Android TV support — full D-pad navigable TV interface with side rail, discover, browse, and favourites
- Magenta-accented light and dark themes with a saved system/light/dark appearance choice
- Lazy genre browsing, bounded artwork decoding and cached station images
- Neutral initials for unavailable artwork and stable group ordering as image failures are learned

## Installation

Two separate APKs are available — one for phones and one for Android TV. Download the right one for your device from the [latest release](https://github.com/Natboa/RadioV2-Android/releases).

**Phone (Android 8.0+)**

👉 [RadioV2.apk](https://github.com/Natboa/RadioV2-Android/releases)

**Android TV**

👉 [RadioV2-TV.apk](https://github.com/Natboa/RadioV2-Android/releases)

> Enable *Install from unknown sources* in your device settings if prompted.


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

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.
