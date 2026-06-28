import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart' show Gapless;
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/audio/audio_lease.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/core/audio/playback_state.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/utils/cancellation_token.dart';
import 'package:tawaq/feature/quran/data/repository/recitation_repository.dart';
import 'package:tawaq/feature/quran/data/sources/recitation_cache.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_range.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_timeline.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_route_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_data_providers.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_state_machine.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';

export 'recitation_data_providers.dart';

part 'recitation_provider.g.dart';

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

/// Drives Quran recitation through the shared audio service.
///
/// The controller is now a thin layer over [transition]: all state lives in the
/// immutable [RecitationState] and every user/audio event is reduced through
/// the pure state machine. Side effects returned by the machine are executed
/// here (load audio, pause, resume, seek, highlight, persist).
@Riverpod(keepAlive: true)
class RecitationController extends _$RecitationController {
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<PlaybackState>? _stateSub;
  StreamSubscription<int?>? _abLoopSub;
  StreamSubscription<int?>? _trackIndexSub;

  RecitationTimeline _timeline = const RecitationTimeline();
  Timer? _sleepTimer;
  bool _sessionBootstrapped = false;
  String? _lastResolvedUri;
  CancellationToken? _downloadToken;
  int? _lastAbLoopRemaining;
  int? _lastTrackIndex;

  @override
  RecitationState build() {
    final service = ref.watch(tawaqAudioServiceProvider);
    unawaited(_positionSub?.cancel());
    unawaited(_durationSub?.cancel());
    unawaited(_stateSub?.cancel());
    unawaited(_abLoopSub?.cancel());
    unawaited(_trackIndexSub?.cancel());
    _positionSub = service.positionStream.listen(_onPosition);
    _durationSub = service.durationStream.listen(_onDuration);
    _stateSub = service.stateStream.listen(_onServiceState);
    _abLoopSub = service.remainingAbLoopsStream.listen(_onAbLoopRemaining);
    _trackIndexSub = service.currentIndexStream.listen(_onTrackIndexChanged);
    ref
      ..onDispose(() {
        unawaited(_positionSub?.cancel());
        unawaited(_durationSub?.cancel());
        unawaited(_stateSub?.cancel());
        unawaited(_abLoopSub?.cancel());
        unawaited(_trackIndexSub?.cancel());
        _sleepTimer?.cancel();
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
        if (!moshaf.hasTiming) return;
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
  Future<void> switchReciter(Reciter reciter, Moshaf moshaf) async {
    final s = state;
    final surah = s.surah;
    if (surah == null) {
      ref.read(recitationSettingsProvider.notifier).setReciter(
        reciterId: reciter.id,
        moshafId: moshaf.id,
      );
      return;
    }

    // Persist the new selection immediately.
    ref.read(recitationSettingsProvider.notifier).setReciter(
      reciterId: reciter.id,
      moshafId: moshaf.id,
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
  }

  /// Universal play/pause button.
  Future<void> togglePlayPause() async {
    _dispatch(const TogglePlayPause());
  }

  /// Clears the surfaced error.
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  /// Stops audio but keeps the player session visible.
  Future<void> stop() async {
    _dispatch(const Stop());
  }

  /// Seeks within the current surah audio, snapping to the nearest ayah when
  /// timing is available.
  Future<void> seekTo(Duration position) async {
    final snapped = _timeline.snapToNearestAyah(position);
    _dispatch(Seek(snapped));
  }



  /// Sets output volume preview (0-100) without persisting.
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

  /// Advances to the next ayah or surah.
  Future<void> skipNext() async {
    _dispatch(const SkipNext());
  }

  /// Goes to the previous ayah or surah.
  Future<void> skipPrevious() async {
    _dispatch(const SkipPrevious());
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
    _dispatch(const AlertResume());
  }

  // ---- Internals ---------------------------------------------------------

  void _dispatch(RecitationEvent event) {
    final settings = ref.read(recitationSettingsProvider).value;
    final ayahRepeatCount = (settings?.ayahRepeatCount ?? 1).clamp(1, 99);
    final rangeRepeatCount = (settings?.rangeRepeatCount ?? 1).clamp(1, 99);
    final result = transition(
      state,
      event,
      timeline: _timeline,
      defaultAyahRepeatCount: ayahRepeatCount,
      defaultRangeRepeatCount: rangeRepeatCount,
    );
    state = result.state;
    unawaited(_applyEffects(result.effects));
  }

  Future<void> _applyEffects(List<RecitationEffect> effects) async {
    for (final effect in effects) {
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
        case StopAudio():
          await _service.stop(fadeOut: kAudioDefaultFadeOut);
        case SeekAudio():
          if (state.isLoading) break;
          await _service.seek(effect.position, owner: kRecitationLeaseOwner);
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
        case PersistPlaybackState():
          ref.read(recitationSettingsProvider.notifier).setPlaybackState(
            surah: effect.surah,
            rangeStart: effect.rangeStart,
            rangeEnd: effect.rangeEnd,
            rangeFromSurah: effect.rangeFromSurah,
            rangeFromAyah: effect.rangeFromAyah,
            rangeToSurah: effect.rangeToSurah,
            rangeToAyah: effect.rangeToAyah,
          );
      }
    }
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
    if (isRange && !moshaf.hasTiming) {
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
    if (isRange) {
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
        (isRange && localStartAyah != null
            ? _timeline.startOfAyah(localStartAyah)
            : null) ??
        Duration.zero;

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

    if (moshaf.hasTiming && ayahRepeatCount > 1) {
      _lastAbLoopRemaining = null;
      final firstAyah = isRange ? localStartAyah! : 1;
      await _setAyahLoop(firstAyah, ayahRepeatCount);
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
    _dispatch(AudioPosition(position));
  }

  void _onDuration(Duration duration) {
    if (state.suspendedSnapshot != null) return;
    _dispatch(AudioDuration(duration));
  }

  void _onServiceState(PlaybackState playback) {
    if (state.suspendedSnapshot != null) return;
    switch (playback) {
      case PlaybackLoading():
        _dispatch(const AudioLoading());
      case PlaybackPlaying(:final duration):
        _dispatch(const AudioStarted());
        if (duration > Duration.zero) {
          _dispatch(AudioDuration(duration));
        }
      case PlaybackPaused(:final duration):
        _dispatch(const AudioPaused());
        if (duration > Duration.zero) {
          _dispatch(AudioDuration(duration));
        }
      case PlaybackError(:final message):
        _dispatch(AudioError(message));
      case PlaybackIdle():
        if (state.active &&
            !state.userStopped &&
            !state.timelinePending &&
            !state.isLoading &&
            (state.isPlaying || state.isBuffering)) {
          _dispatch(const AudioCompleted());
        }
      case PlaybackBuffering():
        _dispatch(const AudioBuffering());
    }
  }

  Future<void> _applyHighlight(int surah, int ayahNumber) async {
    final settings = ref.read(recitationSettingsProvider).value;
    final highlight = settings?.highlightAyah ?? true;
    final autoScroll = settings?.autoScroll ?? true;
    if (!highlight) return;
    try {
      final ayah = await _mushaf.getAyahBySurah(surah, ayahNumber);
      ref.read(quranScreenSettingsProvider.notifier).selectAyah(ayah);
      final (p1, p2) = _mushaf.currentPages;
      if (ayah.page == p1 || ayah.page == p2) {
        _mushaf.selectAyah(ayah.ayahId);
      } else if (autoScroll && ref.read(quranRouteActiveProvider)) {
        await _mushaf.jumpToAyah(ayah.ayahId, select: true);
      } else {
        _mushaf.selectAyah(ayah.ayahId);
      }
    } on Object catch (error, stack) {
      ref
          .read(loggerProvider)
          .w('Highlight failed', error: error, stackTrace: stack);
    }
  }

  Future<void> _bootstrapSession() async {
    if (state.reciter != null) return;
    try {
      final reciter = await ref.read(selectedReciterProvider.future);
      final moshaf = await ref.read(selectedMoshafProvider.future);
      if (reciter == null || moshaf == null) return;
      final settings = ref.read(recitationSettingsProvider).value;
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
}
