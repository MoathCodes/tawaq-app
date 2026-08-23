import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_track.freezed.dart';

/// Where the audio bytes come from.
enum AudioTrackSource {
  /// Bundled Flutter asset played via mpv `asset://` scheme.
  asset,

  /// Remote HTTP(S) or stream URL.
  network,
}

/// Immutable description of a single playable item.
@freezed
abstract class AudioTrack with _$AudioTrack {
  /// Creates an [AudioTrack].
  const factory({
    required String id,
    required String title,
    required String uri,
    required AudioTrackSource source,
    String? subtitle,
    String? artworkUri,
  }) = _AudioTrack;

  /// Asset bundled under [assetPath] (e.g. `assets/audio/adhan/default.mp3`).
  factory asset({
    required String id,
    required String title,
    required String assetPath,
    String? subtitle,
    String? artworkUri,
  }) => AudioTrack(
    id: id,
    title: title,
    subtitle: subtitle,
    artworkUri: artworkUri,
    source: AudioTrackSource.asset,
    uri: 'asset:///$assetPath',
  );

  /// Network or file URL understood by mpv.
  factory network({
    required String id,
    required String title,
    required String url,
    String? subtitle,
    String? artworkUri,
  }) => AudioTrack(
    id: id,
    title: title,
    subtitle: subtitle,
    artworkUri: artworkUri,
    source: AudioTrackSource.network,
    uri: url,
  );
}
