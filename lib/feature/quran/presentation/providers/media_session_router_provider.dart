import 'dart:async';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/audio/audio_lease.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';

part 'media_session_router_provider.g.dart';

/// Single OS-media-session command router.
///
/// Subscribes to [TawaqAudioService.mediaSessionCommands] for the lifetime of
/// the app and dispatches each command to the owner that currently holds the
/// audio lease: [kRecitationLeaseOwner] commands are routed to
/// [RecitationController] (ayah/surah skip, toggle, seek, stop), while
/// [kAdhanLeaseOwner] commands are routed to [AudioPlayerController] (the
/// adhan transport). Commands with no active lease owner are ignored.
@Riverpod(keepAlive: true)
class MediaSessionCommandRouter extends _$MediaSessionCommandRouter {
  StreamSubscription<MediaSessionCommand>? _sub;

  @override
  void build() {
    final service = ref.watch(tawaqAudioServiceProvider);
    unawaited(_sub?.cancel());
    _sub = service.mediaSessionCommands.listen(_dispatch);
    ref.onDispose(() {
      unawaited(_sub?.cancel());
      _sub = null;
    });
  }

  /// Routes [command] to the current lease owner. Exposed for testing so the
  /// routing table can be exercised without a live OS command stream.
  void dispatch(MediaSessionCommand command) => _dispatch(command);

  void _dispatch(MediaSessionCommand command) {
    final service = ref.read(tawaqAudioServiceProvider);
    switch (service.currentLeaseOwner) {
      case kRecitationLeaseOwner:
        _routeRecitation(command);
      case kAdhanLeaseOwner:
        _routeAdhan(command);
      case null:
        // No active playback — ignore OS commands.
        break;
      case _:
        // Unknown owner — ignore.
        break;
    }
  }

  void _routeRecitation(MediaSessionCommand command) {
    final controller = ref.read(recitationControllerProvider.notifier);
    switch (command) {
      case MediaSessionCommandPlay():
        unawaited(controller.togglePlayPause());
      case MediaSessionCommandPause():
        unawaited(controller.togglePlayPause());
      case MediaSessionCommandPlayPause():
        unawaited(controller.togglePlayPause());
      case MediaSessionCommandStop():
        unawaited(controller.stop());
      case MediaSessionCommandNext():
        unawaited(controller.skipNext());
      case MediaSessionCommandPrevious():
        unawaited(controller.skipPrevious());
      case MediaSessionCommandSeekTo(:final position):
        unawaited(controller.seekTo(position));
      case MediaSessionCommandSeekBy(:final offset):
        // Recitation seeks by ayah, not absolute scrubbing — fall through to
        // skip next/previous on a coarse relative seek.
        if (offset >= Duration.zero) {
          unawaited(controller.skipNext());
        } else {
          unawaited(controller.skipPrevious());
        }
      case MediaSessionCommandSetRepeatMode():
      case MediaSessionCommandSetShuffle():
      case MediaSessionCommandSetPlaybackRate():
      case MediaSessionCommandLike():
        // Not applicable to recitation.
        break;
    }
  }

  void _routeAdhan(MediaSessionCommand command) {
    final audio = ref.read(audioPlayerControllerProvider.notifier);
    switch (command) {
      case MediaSessionCommandPlay():
        unawaited(audio.resume());
      case MediaSessionCommandPause():
        unawaited(audio.pause());
      case MediaSessionCommandPlayPause():
        // Adhan has no resume-from-pause affordance in the UI; a playPause
        // toggle just stops the alert (mirroring the alert card's dismiss).
        unawaited(audio.stop(fadeOut: kAudioDefaultFadeOut));
      case MediaSessionCommandStop():
        unawaited(audio.stop(fadeOut: kAudioDefaultFadeOut));
      case MediaSessionCommandNext():
      case MediaSessionCommandPrevious():
      case MediaSessionCommandSeekTo():
      case MediaSessionCommandSeekBy():
      case MediaSessionCommandSetRepeatMode():
      case MediaSessionCommandSetShuffle():
      case MediaSessionCommandSetPlaybackRate():
      case MediaSessionCommandLike():
        // Adhan is a single fixed clip — no skip/seek/repeat semantics.
        break;
    }
  }
}
