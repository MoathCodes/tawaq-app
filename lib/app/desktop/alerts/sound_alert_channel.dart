import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_event.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_alert_channel.dart';

/// Plays the bundled adhan/iqamah recording with a gentle fade in and out.
///
/// Routes adhan playback through [AdhanAudioController]. Captures a recitation
/// snapshot via the suspend callback for later resume; force-steal inside the
/// audio service stops any prior session when [AdhanAudioController.playTrack]
/// runs.
class SoundAlertChannel implements PrayerAlertChannel {
  /// Creates a [SoundAlertChannel] over [_adhanPlayer].
  new({
    required this._adhanPlayer,
    required this._onCaptureRecitationVolume,
    required this._onSuspend,
    required this._onRestoreRecitationVolume,
    required this._onResume,
    this._onSettlePreview,
  });

  final AdhanAudioController _adhanPlayer;
  final Future<double> Function() _onCaptureRecitationVolume;
  final Future<void> Function() _onSuspend;
  final Future<void> Function(double volume) _onRestoreRecitationVolume;
  final Future<void> Function() _onResume;
  final Future<void> Function()? _onSettlePreview;

  double? _capturedVolume;
  bool _armed = false;

  @override
  String get debugName => 'sound';

  @override
  Future<void> deliver(PrayerAlertEvent event) async {
    final assetPath = event.soundAssetPath;
    if (!event.playSound || assetPath == null) return;

    // A preview already occupies the shared adhan lease. Settle it before
    // capturing volume so this alert cannot nest on top of preview volume.
    await _onSettlePreview?.call();
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
