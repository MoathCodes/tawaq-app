import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/audio/audio_service.dart' show kAudioDefaultFadeOut;
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_event.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_alert_channel.dart';

/// Plays the bundled adhan/iqamah recording with a gentle fade in and out.
class SoundAlertChannel implements PrayerAlertChannel {
  /// Creates a [SoundAlertChannel] over [_audio].
  SoundAlertChannel(this._audio);

  final AudioPlayerController _audio;

  @override
  String get debugName => 'sound';

  @override
  Future<void> deliver(PrayerAlertEvent event) async {
    final assetPath = event.soundAssetPath;
    if (!event.playSound || assetPath == null) return;

    await _audio.setVolume(event.volume);
    // playTrack already fades in by kAudioDefaultFadeIn.
    await _audio.playTrack(
      AudioTrack.asset(
        id: event.slug,
        title: event.soundTitle ?? event.soundSubtitle ?? 'Tawaq',
        assetPath: assetPath,
        subtitle: event.soundSubtitle,
      ),
    );
  }

  @override
  Future<void> cancel() => _audio.stop(fadeOut: kAudioDefaultFadeOut);
}
