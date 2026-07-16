import 'dart:async';
import 'dart:developer' as developer;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/audio/audio_lease.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';

part 'media_session_router_provider.g.dart';

const _seekLogName = 'tawaq.recitation.seek';

/// Single OS-media-session command router.
///
/// Subscribes to [TawaqAudioService.mediaSessionCommands] for the lifetime of
/// the app and dispatches each command to the owner that currently holds the
/// audio lease: [kRecitationLeaseOwner] commands are routed to
/// [RecitationController] (ayah/surah skip, toggle, seek, stop), while
/// [kAdhanLeaseOwner] commands are routed to [AudioPlayerController] (the
/// adhan transport). Commands with no active lease owner are ignored.
///
/// mpv auto-applies play/pause for OS transport buttons. Recitation play/pause
/// handlers consult [TawaqAudioService.playWhenReady] so the app never
/// double-toggles mpv; [RecitationController] state syncs via
/// [TawaqAudioService.stateStream] when native intent already matches.
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
    _logOsCommand(command, owner: kRecitationLeaseOwner);
    final controller = ref.read(recitationControllerProvider.notifier);
    final service = ref.read(tawaqAudioServiceProvider);
    switch (command) {
      case MediaSessionCommandPlay():
        unawaited(_recitationPlay(controller, service));
      case MediaSessionCommandPause():
        unawaited(_recitationPause(controller, service));
      case MediaSessionCommandPlayPause():
        unawaited(controller.togglePlayPause());
      case MediaSessionCommandStop():
        unawaited(controller.stop());
      case MediaSessionCommandNext():
        unawaited(controller.skipNext());
      case MediaSessionCommandPrevious():
        unawaited(controller.skipPrevious());
      case MediaSessionCommandSeekTo(:final position):
        // mpv auto-applies OS SeekTo before emitting the command; position
        // syncs via positionStream — do not re-seek from the app.
        developer.log(
          'OS SeekTo autoAppliedByMpv=true appReapply=false '
          'targetMs=${position.inMilliseconds}',
          name: _seekLogName,
        );
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

  /// OS play: mpv auto-applies resume; sync app state without double-toggling.
  ///
  /// When the selection has [RecitationState.isEnded], replay via the state
  /// machine instead of resuming mpv at EOF.
  Future<void> _recitationPlay(
    RecitationController controller,
    TawaqAudioService service,
  ) async {
    final recitation = ref.read(recitationControllerProvider);
    if (recitation.isLoading) return;

    if (recitation.isEnded) {
      await controller.togglePlayPause();
      return;
    }

    final nativePlaying = service.playWhenReady;
    if (nativePlaying) {
      // mpv already resumed; [RecitationController] catches up via stateStream.
      if (recitation.isIdle || recitation.isError) {
        await controller.togglePlayPause();
      }
      return;
    }

    if (recitation.isPaused ||
        recitation.isIdle ||
        recitation.isError ||
        recitation.isBuffering) {
      await controller.togglePlayPause();
    }
  }

  /// OS pause: mpv auto-applies pause; sync app state without double-toggling.
  Future<void> _recitationPause(
    RecitationController controller,
    TawaqAudioService service,
  ) async {
    final recitation = ref.read(recitationControllerProvider);
    if (recitation.isLoading || recitation.isEnded) return;

    if (!service.playWhenReady) {
      // mpv already paused; app state syncs via stateStream.
      return;
    }

    if (recitation.isPlaying || recitation.isBuffering) {
      await controller.togglePlayPause();
    }
  }

  void _routeAdhan(MediaSessionCommand command) {
    _logOsCommand(command, owner: kAdhanLeaseOwner);
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

  void _logOsCommand(MediaSessionCommand command, {required String owner}) {
    developer.log(
      'OS command received owner=$owner command=$command',
      name: _seekLogName,
    );
  }
}
