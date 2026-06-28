import 'package:tawaq/core/audio/audio_lease.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_event.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_alert_channel.dart';

/// Plays the bundled adhan/iqamah recording with a gentle fade in and out.
///
/// The channel coordinates with the shared audio engine by acquiring an
/// adhan lease around playback, suspending any active recitation before
/// the alert, and restoring volume + resuming once the alert ends.
class SoundAlertChannel implements PrayerAlertChannel {
  /// Creates a [SoundAlertChannel] over [_service].
  SoundAlertChannel({
    required TawaqAudioService service,
    required Future<double> Function() onCaptureRecitationVolume,
    required Future<void> Function() onSuspend,
    required Future<void> Function(double volume) onRestoreRecitationVolume,
    required Future<void> Function() onResume,
  })  : _service = service,
        _onCaptureRecitationVolume = onCaptureRecitationVolume,
        _onSuspend = onSuspend,
        _onRestoreRecitationVolume = onRestoreRecitationVolume,
        _onResume = onResume;

  final TawaqAudioService _service;
  final Future<double> Function() _onCaptureRecitationVolume;
  final Future<void> Function() _onSuspend;
  final Future<void> Function(double volume) _onRestoreRecitationVolume;
  final Future<void> Function() _onResume;

  AudioLease? _adhanLease;
  double? _capturedVolume;

  @override
  String get debugName => 'sound';

  @override
  Future<void> deliver(PrayerAlertEvent event) async {
    final assetPath = event.soundAssetPath;
    if (!event.playSound || assetPath == null) return;

    _capturedVolume = await _onCaptureRecitationVolume();
    await _onSuspend();

    _adhanLease = await _service.acquire(owner: kAdhanLeaseOwner);
    await _service.setVolume(event.volume);
    await _service.play(
      AudioTrack.asset(
        id: event.slug,
        title: event.soundTitle ?? event.soundSubtitle ?? 'Tawaq',
        assetPath: assetPath,
        subtitle: event.soundSubtitle,
      ),
      owner: kAdhanLeaseOwner,
    );
  }

  @override
  Future<void> cancel() async {
    await _service.stop(fadeOut: kAudioDefaultFadeOut, owner: kAdhanLeaseOwner);
    _adhanLease = null;

    final capturedVolume = _capturedVolume;
    if (capturedVolume != null) {
      await _onRestoreRecitationVolume(capturedVolume);
    }
    await _onResume();
  }
}
