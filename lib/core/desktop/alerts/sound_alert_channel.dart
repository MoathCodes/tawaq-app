import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_event.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_alert_channel.dart';

/// Plays the bundled adhan/iqamah recording with a gentle fade in and out.
///
/// Routes adhan playback through [AudioPlayerController]. Captures a recitation
/// snapshot via [_onSuspend] for later resume; force-steal inside the audio
/// service stops any prior session when [playTrack] runs.
class SoundAlertChannel implements PrayerAlertChannel {
  /// Creates a [SoundAlertChannel] over [_adhanPlayer].
  SoundAlertChannel({
    required this._adhanPlayer,
    required this._onCaptureRecitationVolume,
    required this._onSuspend,
    required this._onRestoreRecitationVolume,
    required this._onResume,
  });

  final AudioPlayerController _adhanPlayer;
  final Future<double> Function() _onCaptureRecitationVolume;
  final Future<void> Function() _onSuspend;
  final Future<void> Function(double volume) _onRestoreRecitationVolume;
  final Future<void> Function() _onResume;

  double? _capturedVolume;
  bool _armed = false;

  @override
  String get debugName => 'sound';

  @override
  Future<void> deliver(PrayerAlertEvent event) async {
    final assetPath = event.soundAssetPath;
    if (!event.playSound || assetPath == null) return;

    _capturedVolume = await _onCaptureRecitationVolume();
    await _onSuspend();
    _armed = true;

    await _adhanPlayer.setVolume(event.volume);
    await _adhanPlayer.playTrack(
      AudioTrack.asset(
        id: event.slug,
        title: event.soundTitle ?? event.soundSubtitle ?? 'Tawaq',
        assetPath: assetPath,
        subtitle: event.soundSubtitle,
      ),
    );
  }

  @override
  Future<void> cancel() async {
    if (!_armed) return;
    _armed = false;

    await _adhanPlayer.stop(fadeOut: kAudioDefaultFadeOut, force: true);

    final capturedVolume = _capturedVolume;
    _capturedVolume = null;
    if (capturedVolume != null) {
      await _onRestoreRecitationVolume(capturedVolume);
    }
    await _onResume();
  }
}
