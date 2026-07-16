import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mpv_audio_kit/mpv_audio_kit.dart' show Gapless, Loop;
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/audio/audio_lease.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/core/audio/playback_state.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/routing/route_provider.dart';
import 'package:tawaq/core/utils/cancellation_token.dart';
import 'package:tawaq/feature/quran/data/repository/recitation_repository.dart';
import 'package:tawaq/feature/quran/data/sources/mp3quran_api.dart';
import 'package:tawaq/feature/quran/data/sources/recitation_cache.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_range.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_timeline.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_route_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_state_machine.dart';
import 'package:tawaq/l10n/app_localizations.dart';

part 'recitation_provider.g.dart';

/// Recitation repository (API + on-disk cache).
@Riverpod(keepAlive: true)
RecitationRepository recitationRepository(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return RecitationRepository(
    api: Mp3QuranApi(
      client: client,
      logger: ref.watch(loggerProvider),
    ),
    cache: RecitationCache(
      client: client,
      logger: ref.watch(loggerProvider),
    ),
    logger: ref.watch(loggerProvider),
  );
}

/// The reciter catalog (timing links merged), cached on disk.
@Riverpod(keepAlive: true)
Future<List<Reciter>> reciters(Ref ref) =>
    ref.watch(recitationRepositoryProvider).reciters();

/// The recitation audio files currently cached on disk.
@Riverpod(keepAlive: true)
Future<List<CachedRecitation>> cachedRecitations(Ref ref) =>
    ref.watch(recitationRepositoryProvider).listCached();

/// Total bytes used by cached recitation audio files on disk.
@Riverpod(keepAlive: true)
Future<int> totalCacheBytes(Ref ref) =>
    ref.watch(recitationRepositoryProvider).totalCacheBytes();

/// Live download progress for the in-flight recitation surah download, or
/// null when no download is active (cached, finished, cancelled, or idle).
///
/// Driven by RecitationController via resolveSurahUri's `onProgress`
/// callback; the drawer renders a Cancel button while the controller is
/// loading and this value is non-null.
@riverpod
class RecitationDownloadProgress extends _$RecitationDownloadProgress {
  @override
  DownloadProgress? build() => null;

  /// Updates the latest progress snapshot.
  DownloadProgress? get progress => state;
  set progress(DownloadProgress value) => state = value;

  /// Clears the progress (download finished/cancelled/failed).
  void clear() => state = null;
}

/// Whether the recitation panel is expanded.
@riverpod
class RecitationDrawer extends _$RecitationDrawer {
  @override
  bool build() => false;

  /// Toggles the recitation panel open/closed.
  void toggle() => state = !state;

  /// Opens the recitation panel.
  void open() => state = true;

  /// Closes the recitation panel.
  void close() => state = false;
}

/// The currently selected reciter, falling back to the first timed reciter.
@Riverpod(keepAlive: true)
Future<Reciter?> selectedReciter(Ref ref) async {
  final reciters = await ref.watch(recitersProvider.future);
  if (reciters.isEmpty) return null;
  final id = ref.watch(
    recitationSettingsProvider.select((s) => s.value?.reciterId),
  );
  if (id != null) {
    for (final r in reciters) {
      if (r.id == id) return r;
    }
  }
  for (final r in reciters) {
    if (r.hasTiming) return r;
  }
  return reciters.first;
}

/// The persisted moshaf for [selectedReciterProvider].
@Riverpod(keepAlive: true)
Future<Moshaf?> selectedMoshaf(Ref ref) async {
  final reciter = await ref.watch(selectedReciterProvider.future);
  if (reciter == null) return null;
  final moshafId = ref.watch(
    recitationSettingsProvider.select((s) => s.value?.moshafId),
  );
  return reciter.resolveMoshaf(moshafId);
}

/// Shows a toast when [RecitationState.error] is set.
class RecitationErrorToastListener extends ConsumerWidget {
  /// Creates [RecitationErrorToastListener].
  const RecitationErrorToastListener({required this.child, super.key});

  /// Wrapped shell content.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      recitationControllerProvider.select((p) => p.error),
      (previous, next) {
        if (next == null || next == previous) return;
        showFToast(
          context: context,
          variant: .destructive,
          icon: const Icon(FLucideIcons.triangleAlert),
          title: Text(context.l10n.quranRecitationPlaybackFailed(next)),
        );
        ref.read(recitationControllerProvider.notifier).clearError();
      },
    );
    return child;
  }
}

/// Toast when [RecitationSettingsNotifier.setReciter] auto-toggles highlight.
void showRecitationHighlightAutoChangeToast(
  BuildContext context, {
  required bool enabled,
}) {
  final l10n = context.l10n;
  showFToast(
    context: context,
    duration: const Duration(seconds: 3),
    icon: Icon(enabled ? FLucideIcons.highlighter : FLucideIcons.info),
    title: Text(
      enabled
          ? l10n.quranRecitationHighlightAutoEnabled
          : l10n.quranRecitationHighlightAutoDisabled,
    ),
  );
}

/// Drives Quran recitation through the shared audio service.
///
/// The controller is now a thin layer over [transition]: all state lives in the
/// immutable [RecitationState] and every user/audio event is reduced through
/// the pure state machine. Side effects returned by the machine are executed
/// here (load audio, pause, resume, seek, highlight, persist).
@Riverpod(keepAlive: true)
class RecitationController extends _$RecitationController {
  static const _seekLogPrefix = 'tawaq.recitation.seek';
  static const _pendingSeekToleranceMs = 500;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<PlaybackState>? _stateSub;
  StreamSubscription<void>? _completionSub;
  StreamSubscription<bool>? _playWhenReadySub;
  StreamSubscription<int?>? _abLoopSub;
  StreamSubscription<int?>? _trackIndexSub;

  RecitationTimeline _timeline = const RecitationTimeline();
  Timer? _sleepTimer;
  Timer? _persistDebounce;
  Timer? _pendingSeekTimer;
  bool _sessionBootstrapped = false;
  String? _lastResolvedUri;
  CancellationToken? _downloadToken;
  int? _lastAbLoopRemaining;
  int? _lastTrackIndex;
  Duration? _pendingLoadSeek;
  Duration _lastAcceptedPosition = Duration.zero;

  @override
  RecitationState build() {
    final service = ref.watch(tawaqAudioServiceProvider);
    unawaited(_positionSub?.cancel());
    unawaited(_durationSub?.cancel());
    unawaited(_stateSub?.cancel());
    unawaited(_completionSub?.cancel());
    unawaited(_playWhenReadySub?.cancel());
    unawaited(_abLoopSub?.cancel());
    unawaited(_trackIndexSub?.cancel());
    _positionSub = service.positionStream.listen(_onPosition);
    _durationSub = service.durationStream.listen(_onDuration);
    _stateSub = service.stateStream.listen(_onServiceState);
    _completionSub = service.completionStream.listen((_) => _onNaturalCompletion());
    _playWhenReadySub =
        service.playWhenReadyStream.listen(_onPlayWhenReadyChanged);
    _abLoopSub = service.remainingAbLoopsStream.listen(_onAbLoopRemaining);
    _trackIndexSub = service.currentIndexStream.listen(_onTrackIndexChanged);
    ref
      ..onDispose(() {
        _persistDebounce?.cancel();
        _persistPlaybackCheckpoint();
        unawaited(_positionSub?.cancel());
        unawaited(_durationSub?.cancel());
        unawaited(_stateSub?.cancel());
        unawaited(_completionSub?.cancel());
        unawaited(_playWhenReadySub?.cancel());
        unawaited(_abLoopSub?.cancel());
        unawaited(_trackIndexSub?.cancel());
        _sleepTimer?.cancel();
        _pendingSeekTimer?.cancel();
      })
      ..listen(
        recitationSettingsProvider.select(
          (s) => (
            s.value?.ayahRepeatCount,
            s.value?.rangeRepeatCount,
          ),
        ),
        (previous, next) {
          if (next.$1 == null && next.$2 == null) return;
          if (next == previous) return;
          _dispatch(
            SetRepeatCounts(
              ayahRepeatCount: next.$1,
              rangeRepeatCount: next.$2,
            ),
          );
        },
      );

    if (!_sessionBootstrapped) {
      _sessionBootstrapped = true;
      unawaited(Future.microtask(_bootstrapSession));
    }

    return const RecitationState(active: true);
  }

  RecitationRepository get _repo => ref.read(recitationRepositoryProvider);
  TawaqAudioService get _service => ref.read(tawaqAudioServiceProvider);
  MushafReaderController get _mushaf => ref.read(quranMushafControllerProvider);

  /// The timing map for the loaded surah, or null when unavailable.
  SurahTiming? get currentTiming => _timeline.timing;

  /// Whether per-ayah timing is loaded for the current surah.
  bool get hasAyahTiming =>
      state.moshaf?.hasTiming == true &&
      (_timeline.hasTiming || state.isLoading || state.timelinePending);

  /// Injects [timeline] for tests of [goToPlaybackInMushaf].
  @visibleForTesting
  set timelineForTest(RecitationTimeline timeline) => _timeline = timeline;

  /// Cancels the in-flight surah download, if one is active.
  ///
  /// The download stream observes its cancellation token and deletes the
  /// partial `.part` file; resolveSurahUri then falls back to the network
  /// URL (or a usable `.part`) and playback proceeds.
  Future<void> cancelDownload() async {
    _downloadToken?.cancel();
  }

  // ---- Public controls ---------------------------------------------------

  /// Plays the whole [surah] for [reciter]/[moshaf] from the beginning.
  Future<void> playSurah({
    required Reciter reciter,
    required Moshaf moshaf,
    required int surah,
  }) async {
    _dispatch(PlaySurah(reciter: reciter, moshaf: moshaf, surah: surah));
  }

  /// Plays ayat [startAyah]..[endAyah] of [surah]. Requires timing data.
  ///
  /// Returns false when [moshaf] lacks timing or ayah bounds cannot be
  /// resolved.
  Future<bool> playRange({
    required Reciter reciter,
    required Moshaf moshaf,
    required int surah,
    required int startAyah,
    required int endAyah,
  }) async {
    if (!moshaf.hasTiming) return false;
    _dispatch(
      PlayRange(
        reciter: reciter,
        moshaf: moshaf,
        from: AyahReference(surah: surah, ayah: startAyah),
        to: AyahReference(surah: surah, ayah: endAyah),
      ),
    );
    return true;
  }

  /// Plays a global ayah range, starting with the first surah-local segment.
  ///
  /// A null [to] means the range is open-ended.
  Future<bool> playAyahRange({
    required Reciter reciter,
    required Moshaf moshaf,
    required AyahReference from,
    AyahReference? to,
  }) async {
    if (!moshaf.hasTiming) return false;
    final segment = firstSegmentForRange(from: from, to: to, mushaf: _mushaf);
    _dispatch(
      PlayRange(
        reciter: reciter,
        moshaf: moshaf,
        from: AyahReference(
          surah: segment.surah,
          ayah: segment.startAyah,
        ),
        to: AyahReference(surah: segment.surah, ayah: segment.endAyah),
        globalFrom: from,
        globalTo: to,
      ),
    );
    return true;
  }

  /// Applies a saved range preset and dispatches the matching play event.
  Future<void> playFromRangePreset({
    required RangeScopePreset preset,
    required Reciter reciter,
    required Moshaf moshaf,
    required AyahReference from,
    AyahReference? to,
  }) async {
    final intent = playbackIntentForPreset(
      preset: preset,
      reciter: reciter,
      moshaf: moshaf,
      from: from,
      to: to,
      mushafReader: _mushaf,
    );
    switch (intent) {
      case PlayWholeSurahIntent(:final resumeFrom):
        _dispatch(
          PlaySurah(
            reciter: reciter,
            moshaf: moshaf,
            surah: intent.surah,
            resumeFrom: resumeFrom,
          ),
        );
      case PlayAyahRangeIntent(:final resumeFrom):
        if (!moshaf.hasTiming &&
            !isWholeSurahEndpoints(intent.from, intent.to, _mushaf)) {
          return;
        }
        final segment = firstSegmentForRange(
          from: intent.from,
          to: intent.to,
          mushaf: _mushaf,
        );
        _dispatch(
          PlayRange(
            reciter: reciter,
            moshaf: moshaf,
            from: AyahReference(
              surah: segment.surah,
              ayah: segment.startAyah,
            ),
            to: AyahReference(surah: segment.surah, ayah: segment.endAyah),
            globalFrom: intent.from,
            globalTo: intent.to,
            resumeFrom: resumeFrom,
          ),
        );
    }
  }

  /// Switches to [reciter]/[moshaf] and continues the current surah/range.
  ///
  /// Returns whether ayah highlighting was auto-toggled by the selection.
  Future<bool?> switchReciter(Reciter reciter, Moshaf moshaf) async {
    final s = state;
    final surah = s.surah;
    if (surah == null) {
      return ref.read(recitationSettingsProvider.notifier).setReciter(
        reciterId: reciter.id,
        moshafId: moshaf.id,
        moshafName: moshaf.name,
      );
    }

    // Persist the new selection immediately.
    final autoHighlight = ref
        .read(recitationSettingsProvider.notifier)
        .setReciter(
          reciterId: reciter.id,
          moshafId: moshaf.id,
          moshafName: moshaf.name,
        );

    // Try to resume at the same ayah position when both moshafs have timing.
    Duration? resumeFrom;
    final currentAyah = s.currentAyah;
    if (moshaf.hasTiming && currentAyah != null) {
      final timing = await _repo.timing(surah, moshaf.timingReadId!);
      if (timing != null) {
        final segment = timing.forAyah(currentAyah);
        if (segment != null) {
          resumeFrom = Duration(milliseconds: segment.startMs);
        }
      }
    }

    if (s.isRange && s.currentSegmentRefs != null) {
      final seg = s.currentSegmentRefs!;
      _dispatch(
        PlayRange(
          reciter: reciter,
          moshaf: moshaf,
          from: seg.from,
          to: seg.to,
          globalFrom: s.rangeFrom,
          globalTo: s.rangeTo,
          resumeFrom: resumeFrom,
        ),
      );
    } else {
      _dispatch(
        PlaySurah(
          reciter: reciter,
          moshaf: moshaf,
          surah: surah,
          resumeFrom: resumeFrom,
        ),
      );
    }
    return autoHighlight;
  }
  Future<void> togglePlayPause() async {
    final trackLoaded = _service.hasActiveTrack;
    _seekLog(
      'togglePlayPause trackLoaded=$trackLoaded '
      'playWhenReady=${trackLoaded ? _service.playWhenReady : null} '
      'status=${state.status}',
    );
    _dispatch(
      const TogglePlayPause(),
      trackLoaded: trackLoaded,
      nativePlayWhenReady: trackLoaded ? _service.playWhenReady : null,
    );
  }

  /// Clears the surfaced error.
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  /// Navigates the mushaf to the current playback location.
  ///
  /// Untimed reciters open the playing surah's start page. Timed reciters jump
  /// to the current ayah and select it, ignoring highlight/auto-scroll toggles.
  Future<void> goToPlaybackInMushaf(BuildContext context) async {
    final s = state;
    final surah = s.surah;
    if (surah == null) return;

    if (!ref.read(quranRouteActiveProvider)) {
      const QuranRoute().go(context);
    }

    if (s.moshaf?.hasTiming == true) {
      final ayahNumber = s.currentAyah ?? _timeline.ayahAt(s.position);
      if (ayahNumber != null) {
        try {
          final ayah = await _mushaf.getAyahBySurah(surah, ayahNumber);
          ref.read(quranScreenSettingsProvider.notifier).selectAyah(ayah);
          await _scrollToAyah(ayah.ayahId, select: true);
        } on Object catch (error, stack) {
          ref.read(loggerProvider).w(
            'Go to playback mushaf failed',
            error: error,
            stackTrace: stack,
          );
        }
        return;
      }
    }

    ref.read(quranScreenSettingsProvider.notifier).selectAyah(null);
    _mushaf.clearSelection();
    await _scrollToSurahWhenReady(surah);
  }

  /// Stops audio but keeps the player session visible.
  Future<void> stop() async {
    _dispatch(const Stop());
  }

  /// Seeks within the current surah audio.
  ///
  /// The seek bar snaps to ayah starts before calling this; the state machine
  /// reconciles repeat/loop/highlight state.
  Future<void> seekTo(Duration position) async {
    _seekLog(
      'seekTo entry targetMs=${position.inMilliseconds} '
      'posMs=${state.position.inMilliseconds} '
      'pendingMs=${state.pendingSeekTarget?.inMilliseconds} '
      'loadGen=${state.loadGeneration}',
    );
    _dispatch(Seek(position));
  }

  /// Advances to the next ayah within the current surah/range.
  Future<void> skipAyahNext() async {
    _dispatch(const SkipAyahNext());
  }

  /// Goes to the previous ayah within the current surah/range.
  Future<void> skipAyahPrevious() async {
    _dispatch(const SkipAyahPrevious());
  }

  /// Loads the next available surah in the moshaf.
  Future<void> skipSurahNext() async {
    _dispatch(const SkipSurahNext());
  }

  /// Loads the previous available surah in the moshaf.
  Future<void> skipSurahPrevious() async {
    _dispatch(const SkipSurahPrevious());
  }

  /// Skips forward — ayah when timing is available, otherwise surah.
  Future<void> skipNext() async {
    if (hasAyahTiming) {
      await skipAyahNext();
    } else {
      await skipSurahNext();
    }
  }

  /// Skips backward — ayah when timing is available, otherwise surah.
  Future<void> skipPrevious() async {
    if (hasAyahTiming) {
      await skipAyahPrevious();
    } else {
      await skipSurahPrevious();
    }
  }
  Future<void> setVolumePreview(double volume) async {
    ref.read(recitationSettingsProvider.notifier).setVolumePreview(volume);
    await _service.setVolume(volume);
  }

  /// Persists output volume (0-100) after the user releases the slider.
  Future<void> commitVolume(double volume) async {
    ref.read(recitationSettingsProvider.notifier).commitVolume(volume);
    await _service.setVolume(volume);
  }

  /// Arms or clears the sleep timer.
  void setSleep(RecitationSleep sleep) {
    _sleepTimer?.cancel();
    _sleepTimer = null;

    if (sleep.isCountdown) {
      _sleepTimer = Timer(sleep.countdown!, () => unawaited(stop()));
    }

    _dispatch(SetSleep(sleep));
  }

  // ---- Alert coordination ------------------------------------------------

  /// Captures recitation state and releases the player for an alert.
  Future<void> suspendForAlert() async {
    if (state.surah == null ||
        state.reciter == null ||
        state.suspendedSnapshot != null) {
      return;
    }
    if (!state.isPlaying && !state.isPaused) {
      return;
    }
    final settings = ref.read(recitationSettingsProvider).value;
    final ayahRepeatCount = (settings?.ayahRepeatCount ?? 1).clamp(1, 99);
    final rangeRepeatCount = (settings?.rangeRepeatCount ?? 1).clamp(1, 99);
    final result = transition(
      state,
      const AlertSuspend(),
      timeline: _timeline,
      defaultAyahRepeatCount: ayahRepeatCount,
      defaultRangeRepeatCount: rangeRepeatCount,
    );
    state = result.state;
    await _applyEffects(result.effects);
  }

  /// Resumes recitation from the saved position once the alert ends.
  Future<void> resumeAfterAlert() async {
    final snapshot = state.suspendedSnapshot;
    if (snapshot == null) return;

    final canFastResume = snapshot.isPlaying &&
        snapshot.reciter != null &&
        snapshot.moshaf != null &&
        snapshot.surah != null &&
        _lastResolvedUri != null;

    if (canFastResume) {
      final reciter = snapshot.reciter!;
      final moshaf = snapshot.moshaf!;
      final surah = snapshot.surah!;
      final position = snapshot.position;
      final ayahRepeatCount = snapshot.ayahRepeatCount;

      state = snapshot.copyWith(
        suspendedSnapshot: null,
        status: RecitationStatus.loading,
      );

      final settings = ref.read(recitationSettingsProvider).value;
      final volume = settings?.volume ?? 100;
      await _service.setVolume(volume);
      await _service.openAndSeekTo(
        AudioTrack.network(
          id: 'recitation-${reciter.id}-$surah',
          title: _surahTitle(surah),
          url: _lastResolvedUri!,
          subtitle: reciter.name,
        ),
        start: position,
        owner: kRecitationLeaseOwner,
      );

      if (moshaf.hasTiming &&
          ayahRepeatCount > 1 &&
          snapshot.currentAyah != null) {
        _lastAbLoopRemaining = null;
        await _setAyahLoop(snapshot.currentAyah!, ayahRepeatCount);
      }
      await _publishRecitationMediaSession(
        surah: surah,
        reciterName: reciter.name,
      );
      return;
    }

    _dispatch(const AlertResume());
  }

  // ---- Internals ---------------------------------------------------------

  void _seekLog(String message) {
    ref.read(loggerProvider).d('[$_seekLogPrefix] $message');
  }

  void _dispatch(
    RecitationEvent event, {
    bool trackLoaded = false,
    bool? nativePlayWhenReady,
  }) {
    switch (event) {
      case SeekFailed(:final revertTo):
        _seekLog(
          'SeekFailed revertToMs=${revertTo.inMilliseconds} '
          'pendingMs=${state.pendingSeekTarget?.inMilliseconds}',
        );
      case PendingSeekTimeout(:final revertTo):
        _seekLog(
          'PendingSeekTimeout revertToMs=${revertTo?.inMilliseconds}',
        );
      default:
        break;
    }
    final settings = ref.read(recitationSettingsProvider).value;
    final ayahRepeatCount = (settings?.ayahRepeatCount ?? 1).clamp(1, 99);
    final rangeRepeatCount = (settings?.rangeRepeatCount ?? 1).clamp(1, 99);
    final result = transition(
      state,
      event,
      timeline: _timeline,
      defaultAyahRepeatCount: ayahRepeatCount,
      defaultRangeRepeatCount: rangeRepeatCount,
      trackLoaded: trackLoaded,
      nativePlayWhenReady: nativePlayWhenReady,
    );
    state = result.state;
    _syncPendingSeekTimeout();
    unawaited(_applyEffects(result.effects));
  }

  void _syncPendingSeekTimeout() {
    if (state.pendingSeekTarget == null) {
      _pendingSeekTimer?.cancel();
      _pendingSeekTimer = null;
      return;
    }
    _pendingSeekTimer?.cancel();
    _pendingSeekTimer = Timer(const Duration(seconds: 2), () {
      if (state.pendingSeekTarget != null) {
        _seekLog(
          'PendingSeekTimeout firing revertToMs='
          '${_lastAcceptedPosition.inMilliseconds}',
        );
        _dispatch(PendingSeekTimeout(revertTo: _lastAcceptedPosition));
      }
    });
  }

  Future<void> _applyEffects(List<RecitationEffect> effects) async {
    final deferred = <RecitationEffect>[];
    final hasLoad = effects.any(
      (effect) =>
          effect is LoadSurah ||
          effect is LoadRange ||
          effect is LoadGaplessContinuation ||
          effect is LoadNextRangeSegment,
    );

    Future<void> applyOne(RecitationEffect effect) async {
      switch (effect) {
        case LoadSurah():
          await _load(
            reciter: effect.reciter,
            moshaf: effect.moshaf,
            surah: effect.surah,
            resumeFrom: effect.seekTo,
          );
        case LoadRange():
          await _load(
            reciter: effect.reciter,
            moshaf: effect.moshaf,
            surah: effect.from.surah,
            startAyah: effect.from.ayah,
            endAyah: effect.to?.ayah,
            resumeFrom: effect.seekTo,
          );
        case PauseAudio():
          await _service.pause();
        case ReleaseAudioLease():
          await _service.release(owner: kRecitationLeaseOwner);
        case ResumeAudio():
          await _service.resume();
          final resumeSurah = state.surah;
          final resumeReciter = state.reciter;
          if (resumeSurah != null && resumeReciter != null) {
            await _publishRecitationMediaSession(
              surah: resumeSurah,
              reciterName: resumeReciter.name,
            );
          }
        case StopAudio():
          await _service.stop(fadeOut: kAudioDefaultFadeOut);
        case SeekAudio():
          if (state.isLoading) {
            _pendingLoadSeek = effect.position;
            break;
          }
          _seekLog(
            'SeekAudio start targetMs=${effect.position.inMilliseconds} '
            'loadGen=${state.loadGeneration}',
          );
          final ok = await _service.seek(
            effect.position,
            owner: kRecitationLeaseOwner,
          );
          _pendingLoadSeek = null;
          if (!ok) {
            _seekLog(
              'SeekAudio failure targetMs=${effect.position.inMilliseconds}',
            );
            _dispatch(SeekFailed(revertTo: _lastAcceptedPosition));
          } else {
            _seekLog(
              'SeekAudio success targetMs=${effect.position.inMilliseconds}',
            );
          }
        case HighlightAyah():
          await _applyHighlight(effect.surah, effect.ayah);
        case CancelSleepTimer():
          _sleepTimer?.cancel();
          _sleepTimer = null;
        case LoadAyahLoop():
          await _setAyahLoop(effect.ayah, state.ayahRepeatCount);
        case LoadGaplessContinuation():
          await _openGaplessContinuation(
            reciter: effect.reciter,
            moshaf: effect.moshaf,
            fromSurah: effect.fromSurah,
            toSurah: effect.toSurah,
          );
        case LoadNextRangeSegment():
          await _loadNextRangeSegment(
            reciter: effect.reciter,
            moshaf: effect.moshaf,
            globalFrom: effect.globalFrom,
            globalTo: effect.globalTo,
            currentSurah: effect.currentSurah,
          );
        case PersistPlaybackState():
          final notifier = ref.read(recitationSettingsProvider.notifier);
          if (effect.positionMs != null && effect.surah != null) {
            notifier.persistPlaybackCheckpoint(
              surah: effect.surah!,
              positionMs: effect.positionMs!,
              rangeStart: effect.rangeStart,
              rangeEnd: effect.rangeEnd,
              rangeFromSurah: effect.rangeFromSurah,
              rangeFromAyah: effect.rangeFromAyah,
              rangeToSurah: effect.rangeToSurah,
              rangeToAyah: effect.rangeToAyah,
            );
          } else {
            notifier.setPlaybackState(
              surah: effect.surah,
              rangeStart: effect.rangeStart,
              rangeEnd: effect.rangeEnd,
              rangeFromSurah: effect.rangeFromSurah,
              rangeFromAyah: effect.rangeFromAyah,
              rangeToSurah: effect.rangeToSurah,
              rangeToAyah: effect.rangeToAyah,
            );
          }
        case ClearPlaybackPosition():
          ref.read(recitationSettingsProvider.notifier).clearPlaybackPosition();
        case SetNativeLoop(:final mode):
          await _service.setLoop(
            mode == NativeLoopMode.file ? Loop.file : Loop.off,
          );
        case ClearNativeAbLoop():
          await _service.clearAbLoop();
        case ResetNativePlaybackModes():
          await _service.resetPlaybackModes();
        case PauseAtEof():
          await _service.pauseAtEof();
        case RefreshAbLoop(:final ayah, :final repeatCount):
          await _setAyahLoop(ayah, repeatCount);
      }
    }

    for (final effect in effects) {
      final deferAfterLoad = hasLoad &&
          (effect is SetNativeLoop ||
              effect is LoadAyahLoop ||
              effect is RefreshAbLoop);
      if (deferAfterLoad) {
        deferred.add(effect);
        continue;
      }
      await applyOne(effect);
    }
    for (final effect in deferred) {
      await applyOne(effect);
    }
  }

  void _schedulePersistCheckpoint() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(
      const Duration(milliseconds: 400),
      _persistPlaybackCheckpoint,
    );
  }

  void _persistPlaybackCheckpoint() {
    final s = state;
    if (s.surah == null || s.userStopped || s.isEnded) return;

    Duration position;
    if (s.moshaf?.hasTiming == true && s.currentAyah != null) {
      position = _timeline.startOfAyah(s.currentAyah!) ?? s.position;
    } else {
      position = s.position;
    }
    if (position <= Duration.zero) return;

    final seg = s.currentSegmentRefs;
    ref.read(recitationSettingsProvider.notifier).persistPlaybackCheckpoint(
      surah: s.surah!,
      positionMs: position.inMilliseconds,
      rangeStart: seg?.from.ayah,
      rangeEnd: seg?.to?.ayah,
      rangeFromSurah: s.rangeFrom?.surah,
      rangeFromAyah: s.rangeFrom?.ayah,
      rangeToSurah: s.rangeTo?.surah,
      rangeToAyah: s.rangeTo?.ayah,
    );
  }

  Future<void> _load({
    required Reciter reciter,
    required Moshaf moshaf,
    required int surah,
    int? startAyah,
    int? endAyah,
    Duration? resumeFrom,
  }) async {
    final newGen = state.loadGeneration + 1;
    state = state.copyWith(
      loadGeneration: newGen,
      userStopped: false,
      timelinePending: moshaf.hasTiming,
      status: RecitationStatus.loading,
    );

    try {
      await _service.stop();
    } on Object catch (error, stack) {
      ref.read(loggerProvider).d(
        'Audio stop during load failed (continuing): $error',
        stackTrace: stack,
      );
    }
    _resetTiming();

    final isRange = startAyah != null && endAyah != null;
    final localStart = startAyah;
    final localEnd = endAyah;
    final isUntimedFullSurah = isRange &&
        !moshaf.hasTiming &&
        localStart != null &&
        localEnd != null &&
        isFullSurahSegment(
          surah: surah,
          startAyah: localStart,
          endAyah: localEnd,
          mushaf: _mushaf,
        );
    if (isRange && !moshaf.hasTiming && !isUntimedFullSurah) {
      _dispatch(const AudioError('No timing data for range playback'));
      return;
    }

    final settings = ref.read(recitationSettingsProvider).value;
    final volume = settings?.volume ?? 100;
    final ayahRepeatCount = (settings?.ayahRepeatCount ?? 1).clamp(1, 99);

    final token = _startDownload();
    final resolved = await _repo.resolveSurahUri(
      reciter: reciter,
      moshaf: moshaf,
      surah: surah,
      surahName: _surahTitle(surah),
      cancellationToken: token,
      onProgress: (p) =>
          ref.read(recitationDownloadProgressProvider.notifier).progress = p,
    );
    _finishDownload(token);
    if (newGen != state.loadGeneration) return;
    _lastResolvedUri = resolved.uri;

    if (moshaf.hasTiming) {
      final timing = await _repo.timing(surah, moshaf.timingReadId!);
      if (newGen != state.loadGeneration) return;
      _timeline = timelineFor(state, timing);
      // Timeline resolved: clear the load-pending flag so a subsequent
      // PlaybackIdle (natural eof) can dispatch AudioCompleted.
      if (newGen == state.loadGeneration && state.timelinePending) {
        state = state.copyWith(timelinePending: false);
      }
      // Proactively report the timeline's total duration so the seek bar
      // enables immediately, without waiting for mpv's stream.duration (which
      // some timed reciters report late or not at all). The machine's
      // _onAudioDuration keeps the larger value, so a later mpv report that
      // exceeds this will still win.
      final total = _timeline.totalDuration;
      if (newGen == state.loadGeneration && total > state.duration) {
        state = state.copyWith(duration: total);
      }
    }

    final localStartAyah = startAyah;
    final localEndAyah = endAyah;
    if (isRange && moshaf.hasTiming) {
      if (localStartAyah == null ||
          localEndAyah == null ||
          _timeline.timing == null ||
          _timeline.startOfAyah(localStartAyah) == null ||
          _timeline.endOfAyah(localEndAyah) == null) {
        _dispatch(const AudioError('Ayah timing unavailable'));
        return;
      }
    }

    final seekTo = resumeFrom ??
        (isRange && !isUntimedFullSurah && localStartAyah != null
            ? _timeline.startOfAyah(localStartAyah)
            : null) ??
        Duration.zero;

    final uriScheme =
        resolved.uri.startsWith('file://') ? 'file' : 'http';
    _seekLog(
      '_load openAndSeekTo surah=$surah uriScheme=$uriScheme '
      'seekToMs=${seekTo.inMilliseconds} loadGen=$newGen',
    );

    await _service.setVolume(volume);
    await _service.openAndSeekTo(
      AudioTrack.network(
        id: 'recitation-${reciter.id}-$surah',
        title: _surahTitle(surah),
        url: resolved.uri,
        subtitle: reciter.name,
      ),
      start: seekTo,
      owner: kRecitationLeaseOwner,
    );
    if (newGen != state.loadGeneration) return;

    await _publishRecitationMediaSession(
      surah: surah,
      reciterName: reciter.name,
    );

    if (moshaf.hasTiming && ayahRepeatCount > 1) {
      _lastAbLoopRemaining = null;
      final firstAyah = isRange ? localStartAyah! : 1;
      await _setAyahLoop(firstAyah, ayahRepeatCount);
    }

    final pendingSeek = _pendingLoadSeek;
    if (pendingSeek != null && newGen == state.loadGeneration) {
      _pendingLoadSeek = null;
      await _service.seek(pendingSeek, owner: kRecitationLeaseOwner);
    }
  }

  Future<void> _setAyahLoop(int ayah, int ayahRepeatCount) async {
    final start = _timeline.startOfAyah(ayah);
    final end = _timeline.endOfAyah(ayah);
    if (start == null || end == null) return;
    _lastAbLoopRemaining = null;
    await _service.setAbLoopA(start);
    await _service.setAbLoopB(end);
    await _service.setAbLoopCount(ayahRepeatCount - 1);
  }

  Future<void> _loadNextRangeSegment({
    required Reciter reciter,
    required Moshaf moshaf,
    required AyahReference globalFrom,
    required AyahReference globalTo,
    required int currentSurah,
  }) async {
    final next = nextSegmentForRange(
      from: globalFrom,
      to: globalTo,
      currentSurah: currentSurah,
      mushaf: _mushaf,
    );
    if (next == null) {
      final endedPosition =
          state.duration > Duration.zero ? state.duration : state.position;
      state = state.copyWith(
        status: RecitationStatus.ended,
        position: endedPosition,
        currentAyah: null,
        ayahLoopExiting: false,
      );
      await _service.setLoop(Loop.off);
      await _service.pauseAtEof();
      return;
    }

    _dispatch(
      PlayRange(
        reciter: reciter,
        moshaf: moshaf,
        from: AyahReference(surah: next.surah, ayah: next.startAyah),
        to: AyahReference(surah: next.surah, ayah: next.endAyah),
        globalFrom: globalFrom,
        globalTo: globalTo,
      ),
    );
  }

  Future<void> _openGaplessContinuation({
    required Reciter reciter,
    required Moshaf moshaf,
    required int fromSurah,
    required int toSurah,
  }) async {
    final nextCached = await _repo.isSurahCached(
      reciter: reciter,
      moshaf: moshaf,
      surah: toSurah,
      surahName: _surahTitle(toSurah),
    );
    if (!nextCached) {
      // Fall back to the normal reload path when the next surah is not yet
      // downloaded.
      await _load(
        reciter: reciter,
        moshaf: moshaf,
        surah: toSurah,
      );
      return;
    }

    final newGen = state.loadGeneration + 1;
    state = state.copyWith(loadGeneration: newGen, userStopped: false);

    final token = _startDownload();
    final currentUri = (await _repo.resolveSurahUri(
      reciter: reciter,
      moshaf: moshaf,
      surah: fromSurah,
      surahName: _surahTitle(fromSurah),
      cancellationToken: token,
      onProgress: (p) =>
          ref.read(recitationDownloadProgressProvider.notifier).progress = p,
    )).uri;
    if (newGen != state.loadGeneration) {
      _finishDownload(token);
      return;
    }

    final nextUri = (await _repo.resolveSurahUri(
      reciter: reciter,
      moshaf: moshaf,
      surah: toSurah,
      surahName: _surahTitle(toSurah),
      cancellationToken: token,
      onProgress: (p) =>
          ref.read(recitationDownloadProgressProvider.notifier).progress = p,
    )).uri;
    _finishDownload(token);
    if (newGen != state.loadGeneration) return;

    final currentTrack = AudioTrack.network(
      id: 'recitation-${reciter.id}-$fromSurah',
      title: _surahTitle(fromSurah),
      url: currentUri,
      subtitle: reciter.name,
    );
    final nextTrack = AudioTrack.network(
      id: 'recitation-${reciter.id}-$toSurah',
      title: _surahTitle(toSurah),
      url: nextUri,
      subtitle: reciter.name,
    );

    await _service.openAll(
      [currentTrack, nextTrack],
      index: 1,
      owner: kRecitationLeaseOwner,
    );
    if (newGen != state.loadGeneration) return;
    _lastTrackIndex = 1;
    await _publishRecitationMediaSession(
      surah: toSurah,
      reciterName: reciter.name,
    );
    await _service.setPrefetchPlaylist(true);
    await _service.setGapless(Gapless.yes);
  }

  void _onAbLoopRemaining(int? remaining) {
    if (state.suspendedSnapshot != null) {
      _lastAbLoopRemaining = remaining;
      return;
    }
    final previous = _lastAbLoopRemaining;
    _lastAbLoopRemaining = remaining;
    if (remaining == 0 && previous != null && previous > 0) {
      _dispatch(const AyahLoopExhausted());
    }
  }

  void _onTrackIndexChanged(int? index) {
    if (state.suspendedSnapshot != null) return;
    final previous = _lastTrackIndex;
    _lastTrackIndex = index;
    if (index == null || index < 1) return;
    if (previous != null && previous >= 1) return;
    final surah = state.surah;
    if (surah == null || state.rangeFrom != null) return;
    // Native playlist advanced to the next track. Continue from the first
    // ayah of the current surah (the machine already advanced surah before
    // opening the gapless playlist).
    _dispatch(GaplessTrackAdvanced(surah: surah, ayah: 1));
  }

  void _onPosition(Duration position) {
    if (state.suspendedSnapshot != null) return;
    if (state.userStopped || state.isIdle) {
      _seekLog(
        'AudioPosition ignored reason=userStoppedOrIdle '
        'userStopped=${state.userStopped} idle=${state.isIdle} '
        'posMs=${position.inMilliseconds}',
      );
      return;
    }
    final pending = state.pendingSeekTarget;
    if (pending != null &&
        (position.inMilliseconds - pending.inMilliseconds).abs() >
            _pendingSeekToleranceMs) {
      _seekLog(
        'AudioPosition ignored reason=pendingMismatch '
        'posMs=${position.inMilliseconds} pendingMs=${pending.inMilliseconds}',
      );
    }
    _dispatch(AudioPosition(position));
    if (state.pendingSeekTarget == null) {
      _lastAcceptedPosition = state.position;
    }
    if (state.isPlaying) {
      _schedulePersistCheckpoint();
    }
  }

  void _onDuration(Duration duration) {
    if (state.suspendedSnapshot != null) return;
    _dispatch(AudioDuration(duration));
  }

  bool _shouldDispatchAudioCompleted() {
    return state.active &&
        !state.userStopped &&
        !state.timelinePending &&
        !state.isLoading &&
        (state.isPlaying || state.isBuffering);
  }

  void _onNaturalCompletion() {
    if (state.suspendedSnapshot != null) return;
    if (!_shouldDispatchAudioCompleted()) return;
    _dispatch(const AudioCompleted());
  }

  void _onPlayWhenReadyChanged(bool playWhenReady) {
    if (state.suspendedSnapshot != null) return;
    if (playWhenReady) {
      if (state.userStopped || state.isEnded) return;
      if (state.isPlaying || state.isBuffering) return;
      _dispatch(const AudioStarted());
      return;
    }
    if (state.userStopped || state.isEnded || state.isLoading) return;
    if (_service.state is PlaybackCompleted) return;
    if (state.isPlaying || state.isBuffering) {
      _dispatch(const AudioPaused());
    }
  }

  void _onServiceState(PlaybackState playback) {
    if (state.suspendedSnapshot != null) return;
    switch (playback) {
      case PlaybackLoading():
        _dispatch(const AudioLoading());
      case PlaybackPlaying(:final duration):
        if (duration > Duration.zero) {
          _dispatch(AudioDuration(duration));
        }
      case PlaybackPaused(:final duration):
        if (duration > Duration.zero) {
          _dispatch(AudioDuration(duration));
        }
        _persistDebounce?.cancel();
        _persistPlaybackCheckpoint();
      case PlaybackCompleted(:final duration):
        if (duration > Duration.zero) {
          _dispatch(AudioDuration(duration));
        }
        // Natural EOF is handled exclusively via [completionStream]
        // (_onNaturalCompletion). This branch only mirrors duration for
        // programmatic [TawaqAudioService.pauseAtEof] after the machine has
        // already processed [AudioCompleted].
      case PlaybackError(:final message):
        _dispatch(AudioError(message));
      case PlaybackIdle():
        break;
      case PlaybackBuffering():
        _dispatch(const AudioBuffering());
    }
  }

  Future<void> _applyHighlight(int surah, int ayahNumber) async {
    final settings = ref.read(recitationSettingsProvider).value;
    final highlight = settings?.highlightAyah ?? true;
    final autoScroll = settings?.autoScroll ?? true;
    if (!highlight && !autoScroll) return;

    try {
      final ayah = await _mushaf.getAyahBySurah(surah, ayahNumber);
      if (highlight) {
        ref.read(quranScreenSettingsProvider.notifier).selectAyah(ayah);
      }

      final onQuranRoute = ref.read(quranRouteActiveProvider);
      if (autoScroll && onQuranRoute) {
        await _scrollToAyah(ayah.ayahId, select: highlight);
      } else if (highlight) {
        _mushaf.selectAyah(ayah.ayahId);
      }
    } on Object catch (error, stack) {
      ref
          .read(loggerProvider)
          .w('Highlight failed', error: error, stackTrace: stack);
    }
  }

  Future<void> _scrollToAyah(int ayahId, {required bool select}) async {
    if (!_mushaf.pageController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_scrollToAyah(ayahId, select: select));
      });
      return;
    }
    await _mushaf.jumpToAyah(ayahId, select: select);
  }

  Future<void> _scrollToSurahWhenReady(int surah) async {
    if (!_mushaf.pageController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_scrollToSurahWhenReady(surah));
      });
      return;
    }
    await _mushaf.jumpToSurah(surah);
  }

  Future<void> _bootstrapSession() async {
    if (state.reciter != null) return;
    try {
      final reciter = await ref.read(selectedReciterProvider.future);
      final moshaf = await ref.read(selectedMoshafProvider.future);
      if (reciter == null || moshaf == null) return;
      final settings = ref.read(recitationSettingsProvider).value;
      final positionMs = settings?.lastPlaybackPositionMs;
      _dispatch(
        RecitationSettingsLoaded(
          reciter: reciter,
          moshaf: moshaf,
          surah: settings?.lastSurah,
          rangeFrom: _reference(
            settings?.lastRangeFromSurah,
            settings?.lastRangeFromAyah,
          ),
          rangeTo: _reference(
            settings?.lastRangeToSurah,
            settings?.lastRangeToAyah,
          ),
          resumeFrom: positionMs != null && positionMs > 0
              ? Duration(milliseconds: positionMs)
              : null,
        ),
      );
    } on Object catch (error, stack) {
      ref.read(loggerProvider).w(
        'Recitation session bootstrap failed',
        error: error,
        stackTrace: stack,
      );
    }
  }

  AyahReference? _reference(int? surah, int? ayah) {
    if (surah == null || ayah == null) return null;
    return AyahReference(surah: surah, ayah: ayah);
  }

  void _resetTiming() {
    _timeline = const RecitationTimeline();
  }

  CancellationToken _startDownload() {
    // Cancel any in-flight download from a prior load before starting fresh.
    _downloadToken?.cancel();
    final token = CancellationToken();
    _downloadToken = token;
    ref.read(recitationDownloadProgressProvider.notifier).clear();
    return token;
  }

  void _finishDownload(CancellationToken token) {
    // A newer load may have already swapped in its own token; don't clobber it
    // (the newer load owns the progress UI now).
    if (!identical(_downloadToken, token)) return;
    _downloadToken = null;
    ref.read(recitationDownloadProgressProvider.notifier).clear();
  }

  String _surahTitle(int surah) =>
      _mushaf.getSurahSync(surah)?.displayName ?? 'Surah $surah';

  Future<void> _publishRecitationMediaSession({
    required int surah,
    required String reciterName,
  }) async {
    final l10n = lookupAppLocalizations(Locale(ref.read(localeProvider)));
    await _service.publishMediaSession(
      MediaSessionPublishMetadata(
        title: _surahTitle(surah),
        artist: reciterName,
        appName: l10n.mediaSessionAppName,
        album: l10n.mediaSessionAudioBy('mp3quran.net'),
      ),
    );
  }
}
