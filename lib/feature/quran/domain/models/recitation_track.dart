import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_source.dart';

part 'recitation_track.freezed.dart';

/// Maps a surah/ayah range to a future [AudioTrack].
@freezed
abstract class RecitationTrack with _$RecitationTrack {
  /// Creates a [RecitationTrack].
  const factory RecitationTrack({
    required RecitationSource reciter,
    required int surah,
    required int startAyah,
    required int endAyah,
    String? networkUrl,
  }) = _RecitationTrack;

  const RecitationTrack._();

  /// Converts to [AudioTrack] when [networkUrl] is available.
  AudioTrack? toAudioTrack({required String title}) {
    final url = networkUrl;
    if (url == null || url.isEmpty) return null;
    return AudioTrack.network(
      id: 'recitation-$surah-$startAyah-$endAyah-${reciter.id}',
      title: title,
      url: url,
      subtitle: reciter.displayName,
    );
  }
}
