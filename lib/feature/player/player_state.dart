import 'package:flutter/foundation.dart';
import '../../core/model/station.dart';

@immutable
class PlayerUiState {
  static const _unset = Object();

  final Station? station;
  final List<Station> playlist;
  final bool isPlaying;
  final bool isBuffering;
  final bool isError;
  final String? nowPlayingText;
  final bool isFavourite;

  const PlayerUiState({
    this.station,
    this.playlist = const [],
    this.isPlaying = false,
    this.isBuffering = false,
    this.isError = false,
    this.nowPlayingText,
    this.isFavourite = false,
  });

  bool get isIdle => station == null;

  PlayerUiState copyWith({
    Station? station,
    List<Station>? playlist,
    bool? isPlaying,
    bool? isBuffering,
    bool? isError,
    Object? nowPlayingText = _unset,
    bool? isFavourite,
  }) {
    return PlayerUiState(
      station: station ?? this.station,
      playlist: playlist ?? this.playlist,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isError: isError ?? this.isError,
      nowPlayingText: identical(nowPlayingText, _unset)
          ? this.nowPlayingText
          : nowPlayingText as String?,
      isFavourite: isFavourite ?? this.isFavourite,
    );
  }

  T maybeWhen<T>({
    T Function(
      Station station,
      bool isPlaying,
      bool isBuffering,
      String? nowPlayingText,
      bool isFavourite,
    )?
    active,
    required T Function() orElse,
  }) {
    if (!isIdle && active != null) {
      return active(
        station!,
        isPlaying,
        isBuffering,
        nowPlayingText,
        isFavourite,
      );
    }
    return orElse();
  }
}
