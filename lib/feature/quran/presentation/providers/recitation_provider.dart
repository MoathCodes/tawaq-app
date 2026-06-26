import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart' show Loop;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/core/audio/playback_state.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/quran/data/repository/recitation_repository.dart';
import 'package:tawaq/feature/quran/data/sources/mp3quran_api.dart';
import 'package:tawaq/feature/quran/data/sources/recitation_cache.dart';
import 'package:tawaq/feature/quran/domain/models/ayah_reference.dart';
import 'package:tawaq/feature/quran/domain/models/range_scope_preset.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_mode.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_playback.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_sleep.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_range.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_route_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';

part 'recitation_provider.g.dart';

/// Shared HTTP client for recitation API + downloads.
@Riverpod(keepAlive: true)
http.Client recitationHttpClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
}

/// mp3quran.net API client.
@Riverpod(keepAlive: true)
Mp3QuranApi mp3QuranApi(Ref ref) => Mp3QuranApi(
  client: ref.watch(recitationHttpClientProvider),
  logger: ref.watch(loggerProvider),
);

/// On-disk recitation cache.
@Riverpod(keepAlive: true)
RecitationCache recitationCache(Ref ref) => RecitationCache(
  client: ref.watch(recitationHttpClientProvider),
  logger: ref.watch(loggerProvider),
);

/// Recitation repository (API + cache).
@Riverpod(keepAlive: true)
RecitationRepository recitationRepository(Ref ref) => RecitationRepository(
  api: ref.watch(mp3QuranApiProvider),
  cache: ref.watch(recitationCacheProvider),
  logger: ref.watch(loggerProvider),
);

/// The reciter catalog (timing links merged), cached on disk.
@Riverpod(keepAlive: true)
Future<List<Reciter>> reciters(Ref ref) =>
    ref.watch(recitationRepositoryProvider).reciters();

/// The recitation audio files currently cached on disk.
@Riverpod(keepAlive: true)
Future<List<CachedRecitation>> cachedRecitations(Ref ref) =>
    ref.watch(recitationRepositoryProvider).listCached();

/// Whether the recitation drawer (full transport) is open under the title bar.
@riverpod
class RecitationDrawer extends _$RecitationDrawer {
  @override
  bool build() => false;

  /// Toggles the drawer open/closed.
  void toggle() => state = !state;

  /// Opens the drawer (e.g. when a recitation starts, for discoverability).
  void open() => state = true;

  /// Closes the drawer.
  void close() => state = false;
}

/// The currently selected reciter, falling back to the first timed reciter.
///
/// Kept alive so that reading `selectedReciterProvider.future` from a one-shot
/// callback (no widget watching it) doesn't auto-dispose mid-build across the
/// `await` gaps, which would throw an `UnmountedRefException`. It still
/// rebuilds when the reciter catalog or recitation settings change.
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

/// The persisted moshaf for [selectedReciterProvider], falling back to
/// [Reciter.primaryMoshaf] when the saved moshaf id is unset.
@Riverpod(keepAlive: true)
Future<Moshaf?> selectedMoshaf(Ref ref) async {
  final reciter = await ref.watch(selectedReciterProvider.future);
  if (reciter == null) return null;
  final moshafId = ref.watch(
    recitationSettingsProvider.select((s) => s.value?.moshafId),
  );
  return reciter.resolveMoshaf(moshafId);
}

/// Shows a toast when [RecitationPlayback.playbackError] is set.
class RecitationErrorToastListener extends ConsumerWidget {
  /// Creates [RecitationErrorToastListener].
  const RecitationErrorToastListener({required this.child, super.key});

  /// Wrapped shell content.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      recitationControllerProvider.select((p) => p.playbackError),
      (previous, next) {
        if (next == null || next == previous) return;
        showFToast(
          context: context,
          variant: .destructive,
          icon: const Icon(FLucideIcons.triangleAlert),
          title: Text(context.l10n.quranRecitationPlaybackFailed(next)),
        );
        ref.read(recitationControllerProvider.notifier).clearPlaybackError();
      },
    );
    return child;
  }
}

/// Drives Quran recitation through the shared audio service: surah/ayah/range
/// playback, position→ayah highlight sync, end-of-selection modes, and
/// pause/resume around adhan alerts.
@Riverpod(keepAlive: true)
class RecitationController extends _$RecitationController {
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<PlaybackState>? _stateSub;
  StreamSubscription<int?>? _abLoopSub;

  SurahTiming? _timing;
  final Map<int, Ayah> _ayahCache = {};
  int? _rangeStartMs;
  int? _rangeEndMs;
  int _playsRemaining = 1;
  bool _abLoopActive = false;
  bool _abLoopExhausted = false;
  Timer? _sleepTimer;
  int? _sleepDeadlineMs;
  bool _sleepStopAtSurahEnd = false;
  bool _userStopped = false;
  bool _highlightBusy = false;
  bool _suspendedForAlert = false;
  bool _resumeGuard = false;
  _SuspendedRecitation? _suspended;
  bool _userSeeking = false;
  int _loadGeneration = 0;
  bool _isLoading = false;
  bool _sessionBootstrapped = false;

  /// When non-null, the user has picked a new reciter/moshaf in the dialog but
  /// hasn't committed it via the play button. Stored so [togglePlayPause] can
  /// detect "commit, not toggle" and switch to the new reciter.
  ({Reciter reciter, Moshaf moshaf})? _pendingReciter;

  @override
  RecitationPlayback build() {
    final service = ref.watch(tawaqAudioServiceProvider);
    unawaited(_positionSub?.cancel());
    unawaited(_durationSub?.cancel());
    unawaited(_stateSub?.cancel());
    unawaited(_abLoopSub?.cancel());
    _positionSub = service.positionStream.listen(_onPosition);
    _durationSub = service.durationStream.listen(_onDuration);
    _stateSub = service.stateStream.listen(_onServiceState);
    _abLoopSub = service.remainingAbLoopsStream.listen(_onAbLoopRemaining);
    ref.onDispose(() {
      unawaited(_positionSub?.cancel());
      unawaited(_durationSub?.cancel());
      unawaited(_stateSub?.cancel());
      unawaited(_abLoopSub?.cancel());
      _sleepTimer?.cancel();
    });
    ref.listen(
      recitationSettingsProvider.select((s) => s.value?.repeatCount),
      (previous, next) {
        if (next == null || next == previous) return;
        updateRepeatCount(next);
      },
    );
    if (!_sessionBootstrapped) {
      _sessionBootstrapped = true;
      // Run after [build] returns — reading [state] synchronously inside
      // [_bootstrapSession] would hit an uninitialized notifier.
      Future.microtask(() => unawaited(_bootstrapSession()));
    }
    // Default surah so the transport pill has something to show immediately
    // before _bootstrapSession resolves the saved settings.
    return RecitationPlayback(active: true, surah: 1);
  }

  RecitationRepository get _repo => ref.read(recitationRepositoryProvider);
  TawaqAudioService get _service => ref.read(tawaqAudioServiceProvider);
  MushafReaderController get _mushaf => ref.read(quranMushafControllerProvider);

  /// The timing map for the loaded surah, or null when unavailable. Used by
  /// the drawer scrubber to draw per-ayah tick marks.
  SurahTiming? get currentTiming => _timing;

  // ---- Public controls ---------------------------------------------------

  /// Plays the whole [surah] for [reciter]/[moshaf] from the beginning.
  Future<void> playSurah({
    required Reciter reciter,
    required Moshaf moshaf,
    required int surah,
  }) {
    _resetRepeatBudget();
    return _load(reciter: reciter, moshaf: moshaf, surah: surah);
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
  }) {
    if (!moshaf.hasTiming) return Future.value(false);
    _resetRepeatBudget();
    final from = AyahReference(surah: surah, ayah: startAyah);
    final to = AyahReference(surah: surah, ayah: endAyah);
    return playAyahRange(
      reciter: reciter,
      moshaf: moshaf,
      from: from,
      to: to,
    );
  }

  /// Plays a global ayah range, chaining surah loads when [from] and [to]
  /// span multiple surahs.
  ///
  /// A null [to] means the range is open-ended and continues to the end of the
  /// Quran.
  Future<bool> playAyahRange({
    required Reciter reciter,
    required Moshaf moshaf,
    required AyahReference from,
    AyahReference? to,
  }) {
    if (!moshaf.hasTiming) return Future.value(false);
    if (to != null && !from.isBeforeOrEqual(to)) return Future.value(false);
    _resetRepeatBudget();
    final segment = firstSegmentForRange(
      from: from,
      to: to,
      mushaf: _mushaf,
    );
    return _load(
      reciter: reciter,
      moshaf: moshaf,
      surah: segment.surah,
      startAyah: segment.startAyah,
      endAyah: segment.endAyah,
      rangeFrom: from,
      rangeTo: to,
    );
  }

  /// Clears [RecitationPlayback.playbackError] after it has been shown.
  void clearPlaybackError() {
    if (state.playbackError != null) {
      state = state.copyWith(
        playbackError: null,
        status: RecitationStatus.idle,
      );
    }
  }

  /// Resets the repeat counter from the persisted preference. Called on
  /// user-initiated plays so internal replays/alert-resumes keep their budget.
  void _resetRepeatBudget() {
    final count = ref.read(recitationSettingsProvider).value?.repeatCount ?? 1;
    _playsRemaining = count.clamp(1, 99);
  }

  /// Live-updates the repeat budget while playback is active, syncing the
  /// mpv A-B loop count so the change takes effect immediately.
  void updateRepeatCount(int count) {
    _playsRemaining = count.clamp(1, 99);
    // Sync the A-B loop state when a range is loaded.
    if (_rangeStartMs != null && _rangeEndMs != null) {
      if (_playsRemaining > 1 && !_abLoopActive) {
        // Budget increased from 1 → set up A-B loop now.
        unawaited(_service.setAbLoopA(Duration(milliseconds: _rangeStartMs!)));
        unawaited(_service.setAbLoopB(Duration(milliseconds: _rangeEndMs!)));
        unawaited(_service.setAbLoopCount(_playsRemaining));
        _abLoopActive = true;
      } else if (_playsRemaining > 1 && _abLoopActive) {
        // Budget already active — just update the count.
        unawaited(_service.setAbLoopCount(_playsRemaining));
      } else if (_playsRemaining <= 1 && _abLoopActive) {
        // Budget reduced to 1 — clear A-B loop, fall back to Dart polling.
        unawaited(_service.setAbLoopA(null));
        unawaited(_service.setAbLoopB(null));
        _abLoopActive = false;
      }
    }
  }

  /// Universal play/pause button — always produces valid playback.
  ///
  /// This is the "confirmation" action: whatever weird state the player is in,
  /// pressing play makes it right. It handles pending reciter switches,
  /// idle/error recovery, and normal toggle in one place.
  Future<void> togglePlayPause() async {
    if (state.status == RecitationStatus.loading) return;

    // Pending reciter switch — ignore current playback state and commit.
    if (_pendingReciter != null) {
      final (reciter: r, moshaf: m) = _pendingReciter!;
      _pendingReciter = null;
      state = state.copyWith(pendingReciter: null, pendingMoshaf: null);
      final s = state;
      await _load(
        reciter: r,
        moshaf: m,
        surah: s.surah ?? 1,
        startAyah: s.rangeStart,
        endAyah: s.rangeEnd,
        rangeFrom: s.rangeFrom,
        rangeTo: s.rangeTo,
      );
      return;
    }

    final playback = _service.state;
    if (playback is PlaybackPlaying) {
      await _service.pause();
      return;
    }
    if (playback is PlaybackPaused) {
      if (playback.position.inMilliseconds >=
          (playback.duration.inMilliseconds) - 500) {
        await _service.safeSeek(Duration.zero);
      }
      await _service.resume();
      return;
    }

    // Idle/error — reload from current metadata.
    final s = state;
    var r = s.reciter;
    var m = s.moshaf;
    final surah = s.surah ?? 1;
    if (r == null || m == null) {
      // No reciter loaded — bootstrap from settings/defaults.
      r = await ref.read(selectedReciterProvider.future);
      m = await ref.read(selectedMoshafProvider.future);
      if (r == null || m == null) return;
    }
    await _load(
      reciter: r,
      moshaf: m,
      surah: surah,
      startAyah: s.rangeStart,
      endAyah: s.rangeEnd,
      rangeFrom: s.rangeFrom,
      rangeTo: s.rangeTo,
    );
  }

  /// Selects a reciter/moshaf without starting playback.
  ///
  /// The old audio keeps playing (if any). The new reciter is stored as
  /// [pendingReciter] so the next explicit [togglePlayPause] commits it.
  /// The UI shows the diff and an "Apply" play button.
  void setReciter(Reciter reciter, Moshaf moshaf) {
    _pendingReciter = (reciter: reciter, moshaf: moshaf);
    ref.read(recitationSettingsProvider.notifier).setReciter(
      reciterId: reciter.id,
      moshafId: moshaf.id,
    );
    state = state.copyWith(
      pendingReciter: reciter,
      pendingMoshaf: moshaf,
    );
  }

  /// Cancels a pending reciter switch and reverts to the current recitation.
  void cancelPendingReciter() {
    _pendingReciter = null;
    ref.read(recitationSettingsProvider.notifier).setReciter(
      reciterId: state.reciter!.id,
      moshafId: state.moshaf!.id,
    );
    state = state.copyWith(pendingReciter: null, pendingMoshaf: null);
  }

  /// Saves a range selection (from the range dialog) without starting playback.
  ///
  /// Stops any current playback since the old range is no longer relevant.
  /// User presses [togglePlayPause] to commit.
  ///
  /// A null [to] means the selection is open-ended and continues to the end of
  /// the Quran.
  Future<void> saveRange({
    required AyahReference from,
    AyahReference? to,
    RangeScopePreset? preset,
  }) async {
    _userStopped = true;
    await _service.stop();
    _resetTiming();
    final segment = firstSegmentForRange(from: from, to: to, mushaf: _mushaf);
    state = state.copyWith(
      surah: segment.surah,
      rangeStart: segment.startAyah,
      rangeEnd: segment.endAyah,
      rangeFrom: from,
      rangeTo: to,
      status: RecitationStatus.idle,
      active: true,
      currentAyah: null,
      playbackHighlightAyah: null,
      position: Duration.zero,
      duration: Duration.zero,
    );

    ref.read(recitationSettingsProvider.notifier).setPlaybackState(
      surah: segment.surah,
      rangeStart: segment.startAyah,
      rangeEnd: segment.endAyah,
      rangeFromSurah: from.surah,
      rangeFromAyah: from.ayah,
      rangeToSurah: to?.surah,
      rangeToAyah: to?.ayah,
    );
    ref.read(recitationSettingsProvider.notifier).setLastRangePreset(preset);
  }

  /// Stops audio but keeps the player session visible in the shell.
  Future<void> stop() async {
    _userStopped = true;
    _pendingReciter = null;
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepDeadlineMs = null;
    _sleepStopAtSurahEnd = false;
    await _service.stop(fadeOut: kAudioDefaultFadeOut);
    _resetTiming();
    state = state.copyWith(
      status: RecitationStatus.idle,
      active: true,
      currentAyah: null,
      playbackHighlightAyah: null,
      position: Duration.zero,
      sleep: RecitationSleep.off,
    );
  }

  /// Seeks within the current surah audio.
  Future<void> seekTo(Duration position) async {
    if (state.surah == null) return;
    var posMs = position.inMilliseconds.clamp(0, 1 << 30);
    if (state.isRange) {
      final start = _rangeStartMs ?? 0;
      final end = _rangeEndMs ?? _timing?.totalMs ?? posMs;
      posMs = posMs.clamp(start, end);
    }
    _userSeeking = true;
    try {
      await _safeSeek(posMs);
    } finally {
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 250), () {
          _userSeeking = false;
        }),
      );
    }
  }

  /// Sets the end-of-selection mode and re-evaluates the range boundary.
  void setMode(RecitationMode mode) {
    ref.read(recitationSettingsProvider.notifier).setMode(mode);
    state = state.copyWith(mode: mode);
    _rangeEndMs = (state.isRange && state.rangeEnd != null)
        ? _timing?.forAyah(state.rangeEnd!)?.endMs
        : null;
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

  /// Arms or clears the sleep timer. Countdown options stop after a wall-clock
  /// delay; boundary options stop at the end of the ayah/range/surah.
  void setSleep(RecitationSleep mode) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepDeadlineMs = null;
    _sleepStopAtSurahEnd = false;

    switch (mode) {
      case RecitationSleep.off:
        break;
      case RecitationSleep.after10:
      case RecitationSleep.after20:
      case RecitationSleep.after30:
        _sleepTimer = Timer(
          mode.countdown!,
          () => unawaited(stop()),
        );
      case RecitationSleep.endOfAyah:
        final ayah = state.currentAyah;
        _sleepDeadlineMs = ayah == null ? null : _timing?.forAyah(ayah)?.endMs;
      case RecitationSleep.endOfRange:
        _sleepDeadlineMs = _rangeEndMs;
      case RecitationSleep.endOfSurah:
        _sleepStopAtSurahEnd = true;
    }
    state = state.copyWith(sleep: mode);
  }

  /// Advances to the next ayah when timed, otherwise the next surah.
  ///
  /// For open-ended ranges, keeps the open-ended metadata so the player chrome
  /// still shows "continue from here".
  Future<void> skipNext() async {
    final s = state;
    if (s.reciter == null || s.moshaf == null || s.surah == null) return;

    // Open-ended range: jump to the next ayah while keeping the range open.
    if (s.rangeTo == null) {
      if (_timing != null) {
        final anchor = s.currentAyah ?? s.rangeStart ?? 1;
        final nextAyah = anchor + 1;
        if (_timing!.forAyah(nextAyah) != null) {
          await _load(
            reciter: s.reciter!,
            moshaf: s.moshaf!,
            surah: s.surah!,
            startAyah: nextAyah,
            endAyah: null,
            rangeFrom: s.rangeFrom,
            rangeTo: null,
          );
          return;
        }
      }
      final nextSurah = s.surah! + 1;
      if (nextSurah <= 114 && s.moshaf!.hasSurah(nextSurah)) {
        await _load(
          reciter: s.reciter!,
          moshaf: s.moshaf!,
          surah: nextSurah,
          startAyah: 1,
          endAyah: null,
          rangeFrom: s.rangeFrom,
          rangeTo: null,
        );
      }
      return;
    }

    if (_timing != null) {
      final anchor = s.currentAyah ?? s.rangeEnd ?? s.rangeStart ?? 1;
      final nextAyah = anchor + 1;
      if (_timing!.forAyah(nextAyah) != null) {
        await playRange(
          reciter: s.reciter!,
          moshaf: s.moshaf!,
          surah: s.surah!,
          startAyah: nextAyah,
          endAyah: nextAyah,
        );
        return;
      }
      if (s.isCrossSurahRange) {
        final next = nextSegmentForRange(
          from: s.rangeFrom!,
          to: s.rangeTo,
          currentSurah: s.surah!,
          mushaf: _mushaf,
        );
        if (next != null) {
          await _load(
            reciter: s.reciter!,
            moshaf: s.moshaf!,
            surah: next.surah,
            startAyah: next.startAyah,
            endAyah: next.endAyah,
            rangeFrom: s.rangeFrom,
            rangeTo: s.rangeTo,
          );
          return;
        }
      }
    }

    await _playSurahDelta(1);
  }

  /// Goes to the previous ayah when timed, otherwise the previous surah.
  ///
  /// For open-ended ranges, keeps the open-ended metadata.
  Future<void> skipPrevious() async {
    final s = state;
    if (s.reciter == null || s.moshaf == null || s.surah == null) return;

    // Open-ended range: jump to the previous ayah while keeping the range open.
    if (s.rangeTo == null && s.rangeFrom != null) {
      if (_timing != null) {
        final anchor = s.currentAyah ?? s.rangeStart ?? 1;
        if (anchor > 1 && _timing!.forAyah(anchor - 1) != null) {
          await _load(
            reciter: s.reciter!,
            moshaf: s.moshaf!,
            surah: s.surah!,
            startAyah: anchor - 1,
            endAyah: null,
            rangeFrom: s.rangeFrom,
            rangeTo: null,
          );
          return;
        }
      }
      final prevSurah = s.surah! - 1;
      if (prevSurah >= 1 &&
          prevSurah >= s.rangeFrom!.surah &&
          s.moshaf!.hasSurah(prevSurah)) {
        final ayahCount = _mushaf.getSurahSync(prevSurah)?.ayahCount ?? 1;
        await _load(
          reciter: s.reciter!,
          moshaf: s.moshaf!,
          surah: prevSurah,
          startAyah: ayahCount,
          endAyah: null,
          rangeFrom: s.rangeFrom,
          rangeTo: null,
        );
      }
      return;
    }

    if (_timing != null) {
      final anchor = s.currentAyah ?? s.rangeStart ?? 1;
      if (anchor > 1 && _timing!.forAyah(anchor - 1) != null) {
        final prev = anchor - 1;
        await playRange(
          reciter: s.reciter!,
          moshaf: s.moshaf!,
          surah: s.surah!,
          startAyah: prev,
          endAyah: prev,
        );
        return;
      }
      if (s.isCrossSurahRange &&
          s.rangeFrom != null &&
          s.surah! > s.rangeFrom!.surah) {
        final prevSurah = s.surah! - 1;
        final ayahCount = _mushaf.getSurahSync(prevSurah)?.ayahCount ?? 1;
        final endAyah = prevSurah == s.rangeFrom!.surah
            ? s.rangeFrom!.ayah
            : ayahCount;
        await _load(
          reciter: s.reciter!,
          moshaf: s.moshaf!,
          surah: prevSurah,
          startAyah: endAyah,
          endAyah: endAyah,
          rangeFrom: s.rangeFrom,
          rangeTo: s.rangeTo,
        );
        return;
      }
    }

    await _playSurahDelta(-1);
  }

  // ---- Alert coordination ------------------------------------------------

  /// Captures recitation state and releases the player so an adhan/iqamah alert
  /// can play. Paired with [resumeAfterAlert].
  Future<void> suspendForAlert() async {
    if (state.surah == null || state.reciter == null || _suspendedForAlert) {
      return;
    }
    final playback = _service.state;
    final wasPlaying =
        playback is PlaybackPlaying || playback is PlaybackLoading;
    _suspended = _SuspendedRecitation(
      reciter: state.reciter!,
      moshaf: state.moshaf!,
      surah: state.surah!,
      rangeStart: state.rangeStart,
      rangeEnd: state.rangeEnd,
      rangeFrom: state.rangeFrom,
      rangeTo: state.rangeTo,
      positionMs: _service.player.state.position.inMilliseconds,
      wasPlaying: wasPlaying,
    );
    _suspendedForAlert = true;
    _resumeGuard = false;
    // Let the alert channel own the player; pause our recitation first.
    await _service.pause();
  }

  /// Resumes recitation from the saved position once the alert ends or is
  /// dismissed. Idempotent — safe to call from multiple teardown paths.
  Future<void> resumeAfterAlert() async {
    if (!_suspendedForAlert || _resumeGuard) return;
    _resumeGuard = true;
    _suspendedForAlert = false;
    final saved = _suspended;
    _suspended = null;
    if (saved == null || !saved.wasPlaying) return;
    await _load(
      reciter: saved.reciter,
      moshaf: saved.moshaf,
      surah: saved.surah,
      startAyah: saved.rangeStart,
      endAyah: saved.rangeEnd,
      resumeFromMs: saved.positionMs,
    );
  }

  // ---- Internals ---------------------------------------------------------

  Future<bool> _load({
    required Reciter reciter,
    required Moshaf moshaf,
    required int surah,
    int? startAyah,
    int? endAyah,
    AyahReference? rangeFrom,
    AyahReference? rangeTo,
    int? resumeFromMs,
  }) async {
    // Skip reload if the exact same selection is already loaded — just resume
    // if paused. Only meaningful when the service actually has audio loaded
    // (not idle/error) — after hot restart or saveRange the state metadata may
    // match but the service has nothing loaded yet.
    if (reciter.id == state.reciter?.id &&
        moshaf.id == state.moshaf?.id &&
        surah == state.surah &&
        startAyah == state.rangeStart &&
        endAyah == state.rangeEnd) {
      final s = _service.state;
      if (s is PlaybackPaused) {
        await _service.resume();
        return true;
      }
      if (s is PlaybackPlaying) return true;
      // Service is idle/error — fall through to actual load.
    }

    // Any full load commits a pending reciter switch.
    _pendingReciter = null;
    state = state.copyWith(pendingReciter: null, pendingMoshaf: null);

    final generation = ++_loadGeneration;
    _isLoading = true;
    _abLoopExhausted = false;
    _userStopped = true;
    _pendingReciter = null;
    try {
      await _service.stop();
    } finally {
      if (generation == _loadGeneration) _isLoading = true;
    }
    _resetTiming();

    final isRange = startAyah != null && endAyah != null;
    if (isRange && !moshaf.hasTiming) {
      _isLoading = false;
      return false;
    }

    final settings = ref.read(recitationSettingsProvider).value;
    final mode = settings?.mode ?? RecitationMode.stopAtEnd;
    final volume = settings?.volume ?? 100;

    // Emit loading state immediately so the UI shows a spinner.
    state = state.copyWith(
      status: RecitationStatus.loading,
      active: true,
      surah: surah,
    );

    final uri = await _repo.resolveSurahUri(
      reciter: reciter,
      moshaf: moshaf,
      surah: surah,
      surahName: _surahTitle(surah),
    );
    if (generation != _loadGeneration) {
      _isLoading = false;
      return false;
    }

    final isCached = uri.startsWith('file');

    if (moshaf.hasTiming) {
      _timing = await _repo.timing(surah, moshaf.timingReadId!);
    }
    if (generation != _loadGeneration) {
      _isLoading = false;
      return false;
    }

    if (isRange) {
      final from = startAyah;
      final to = endAyah;
      if (_timing == null ||
          _timing!.forAyah(from) == null ||
          _timing!.forAyah(to) == null) {
        state = state.copyWith(
          status: RecitationStatus.idle,
          active: true,
          downloading: false,
        );
        _isLoading = false;
        return false;
      }
    }

    // Resolve range markers from timing data. Always set the end marker when
    // an explicit end exists; the end-of-selection mode decides what to do
    // when it is reached.
    final timingTotal = _timing?.totalMs ?? 0;
    _rangeStartMs = (startAyah != null)
        ? _timing?.forAyah(startAyah)?.startMs
        : null;
    _rangeEndMs = endAyah != null ? _timing?.forAyah(endAyah)?.endMs : null;

    if (generation != _loadGeneration) {
      _isLoading = false;
      return false;
    }

    // Emit the full metadata atomically — one shot, no incremental updates.
    state = RecitationPlayback(
      reciter: reciter,
      moshaf: moshaf,
      surah: surah,
      rangeStart: startAyah,
      rangeEnd: endAyah,
      rangeFrom:
          rangeFrom ??
          (startAyah != null
              ? AyahReference(surah: surah, ayah: startAyah)
              : null),
      rangeTo:
          rangeTo ??
          (endAyah != null
              ? AyahReference(surah: surah, ayah: endAyah)
              : null),
      mode: mode,
      downloading: !isCached,
      active: true,
      sleep: state.sleep,
      duration: timingTotal > 0
          ? Duration(milliseconds: timingTotal)
          : Duration.zero,
      status: RecitationStatus.loading,
    );

    await _service.setVolume(volume);
    await _service.play(
      AudioTrack.network(
        id: 'recitation-${reciter.id}-$surah',
        title: _surahTitle(surah),
        url: uri,
        subtitle: reciter.name,
      ),
    );
    if (generation != _loadGeneration) {
      await _service.stop();
      _isLoading = false;
      return false;
    }

    final seekMs = resumeFromMs ?? _rangeStartMs;
    if (seekMs != null && seekMs > 0) {
      if (generation != _loadGeneration) {
        _isLoading = false;
        return false;
      }
      await _safeSeek(seekMs, generation: generation);
    }
    if (generation != _loadGeneration) {
      _isLoading = false;
      return false;
    }

    // Set up mpv native A-B loop for single-surah ranges.
    if (isRange &&
        _rangeStartMs != null &&
        _rangeEndMs != null &&
        _playsRemaining > 1) {
      await _service.setAbLoopA(Duration(milliseconds: _rangeStartMs!));
      await _service.setAbLoopB(Duration(milliseconds: _rangeEndMs!));
      await _service.setAbLoopCount(_playsRemaining);
      _abLoopActive = true;
    } else {
      await _service.setAbLoopA(null);
      await _service.setAbLoopB(null);
      _abLoopActive = false;
    }

    await _service.setLoop(Loop.off);

    // Persist the current playback state for session restore.
    final s = state;
    ref.read(recitationSettingsProvider.notifier).setPlaybackState(
      surah: s.surah,
      rangeStart: s.rangeStart,
      rangeEnd: s.rangeEnd,
      rangeFromSurah: s.rangeFrom?.surah,
      rangeFromAyah: s.rangeFrom?.ayah,
      rangeToSurah: s.rangeTo?.surah,
      rangeToAyah: s.rangeTo?.ayah,
    );

    if (!isCached) {
      state = state.copyWith(downloading: false);
    }
    _isLoading = false;
    return true;
  }

  Future<void> _playSurahDelta(int delta) async {
    final s = state;
    final reciter = s.reciter;
    final moshaf = s.moshaf;
    final surah = s.surah;
    if (reciter == null || moshaf == null || surah == null) return;
    final next = surah + delta;
    if (next < 1 || next > 114 || !moshaf.hasSurah(next)) {
      if (delta < 0) {
        await seekTo(Duration.zero);
      }
      return;
    }
    await playSurah(reciter: reciter, moshaf: moshaf, surah: next);
  }

  /// Records the player's reported total duration. The controller is subscribed
  /// from app start (it outlives the drawer), so it never misses media_kit's
  /// one-time duration emit the way a late widget subscription does.
  void _onDuration(Duration d) {
    if (_suspendedForAlert || state.surah == null) return;
    if (d.inMilliseconds <= 0) return;

    // mpv can briefly report a segment-local duration after a range seek;
    // never shrink below the timing-derived surah length so the scrubber
    // keeps the full timeline.
    final timingMs = _timing?.totalMs ?? 0;
    final candidateMs = timingMs > 0 && d.inMilliseconds < timingMs
        ? timingMs
        : d.inMilliseconds;

    final resolved = Duration(milliseconds: candidateMs);
    if (resolved != state.duration) {
      state = state.copyWith(duration: resolved);
    }
  }

  void _onPosition(Duration position) {
    if (_suspendedForAlert || state.surah == null) return;
    final posMs = position.inMilliseconds;

    // Keep position in sync on every tick so the scrubber has a consistent
    // view alongside status, duration, and currentAyah from one provider.
    state = state.copyWith(position: position);

    // Sleep timer: stop at the ayah/range content boundary.
    final sleepMs = _sleepDeadlineMs;
    if (sleepMs != null && posMs >= sleepMs) {
      unawaited(_pauseAtEndOfSession());
      return;
    }

    // Stop / loop at the end of a bounded range (skip while the user scrubs).
    final endMs = _rangeEndMs;
    if (!_userSeeking && endMs != null && posMs >= endMs) {
      unawaited(_onSelectionEnd());
      return;
    }

    _syncHighlight(posMs);
  }

  void _syncHighlight(int posMs) {
    final timing = _timing;
    final surah = state.surah;
    if (timing == null || surah == null || _highlightBusy) return;
    final ayahNumber = timing.ayahAt(posMs);
    if (ayahNumber == null || ayahNumber == state.currentAyah) return;
    state = state.copyWith(currentAyah: ayahNumber);
    _refreshSleepEndOfAyah(ayahNumber);
    _highlightBusy = true;
    unawaited(
      _applyHighlight(surah, ayahNumber).whenComplete(() {
        _highlightBusy = false;
      }),
    );
  }

  Future<void> _applyHighlight(int surah, int ayahNumber) async {
    final settings = ref.read(recitationSettingsProvider).value;
    final highlight = settings?.highlightAyah ?? true;
    final autoScroll = settings?.autoScroll ?? true;
    if (!highlight) return;
    try {
      var ayah = _ayahCache[ayahNumber];
      ayah ??= await _mushaf.getAyahBySurah(surah, ayahNumber);
      _ayahCache[ayahNumber] = ayah;
      state = state.copyWith(playbackHighlightAyah: ayah);
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

  void _onServiceState(PlaybackState playback) {
    if (_suspendedForAlert) return;
    switch (playback) {
      case PlaybackLoading():
        state = state.copyWith(status: RecitationStatus.loading);
      case PlaybackPlaying(:final position):
        state = state.copyWith(
          status: RecitationStatus.playing,
          position: position,
        );
      case PlaybackPaused(:final position):
        state = state.copyWith(
          status: RecitationStatus.paused,
          position: position,
        );
      case PlaybackError(:final message):
        _resetTiming();
        state = state.copyWith(
          status: RecitationStatus.error,
          active: true,
          currentAyah: null,
          playbackHighlightAyah: null,
          downloading: false,
          playbackError: message,
        );
      case PlaybackIdle():
        if (state.active && !_userStopped && !_isLoading) {
          unawaited(_handleEndOfSurah());
        }
    }
  }

  /// Called when the mpv A-B loop counter decrements. When a finite loop
  /// exhausts all repetitions the player stops looping; we then apply the
  /// end-of-selection mode (with sleep timer awareness).
  void _onAbLoopRemaining(int? remaining) {
    if (_suspendedForAlert || state.surah == null || _isLoading) return;
    if (remaining != null && remaining <= 0) {
      _abLoopExhausted = true;
      unawaited(_onSelectionEnd());
    }
  }

  /// Handles reaching the end of a bounded range: replays while the repeat
  /// budget remains, otherwise applies the end-of-selection [RecitationMode].
  Future<void> _onSelectionEnd() async {
    if (_abLoopExhausted) {
      _abLoopExhausted = false;
      // A-B loop already consumed the budget; skip _replayForRepeat().
    } else if (_replayForRepeat()) {
      await _safeSeek(_rangeStartMs ?? 0);
      return;
    }

    final s = state;

    // Open-ended range: continue to the next surah, preserving the start point.
    if (s.rangeFrom != null &&
        s.rangeTo == null &&
        s.surah != null &&
        s.reciter != null &&
        s.moshaf != null &&
        s.mode == RecitationMode.continueToNextSurah) {
      final nextSurah = s.surah! + 1;
      if (nextSurah <= 114 && s.moshaf!.hasSurah(nextSurah)) {
        await _load(
          reciter: s.reciter!,
          moshaf: s.moshaf!,
          surah: nextSurah,
          startAyah: 1,
          endAyah: null,
          rangeFrom: s.rangeFrom,
          rangeTo: null,
        );
        return;
      }
    }

    if (s.isCrossSurahRange &&
        s.rangeFrom != null &&
        s.rangeTo != null &&
        s.surah != null &&
        s.rangeEnd != null &&
        !isGlobalRangeComplete(
          to: s.rangeTo,
          surah: s.surah!,
          endAyah: s.rangeEnd!,
          mushaf: _mushaf,
        )) {
      final next = nextSegmentForRange(
        from: s.rangeFrom!,
        to: s.rangeTo,
        currentSurah: s.surah!,
        mushaf: _mushaf,
      );
      if (next != null && s.reciter != null && s.moshaf != null) {
        await _load(
          reciter: s.reciter!,
          moshaf: s.moshaf!,
          surah: next.surah,
          startAyah: next.startAyah,
          endAyah: next.endAyah,
          rangeFrom: s.rangeFrom,
          rangeTo: s.rangeTo,
        );
        return;
      }
    }

    switch (state.mode) {
      case RecitationMode.repeatSelection:
        await _pauseAtEndOfSession();
      case RecitationMode.stopAtEnd:
        await _pauseAtEndOfSession();
      case RecitationMode.continueToNextSurah:
        await skipNext();
    }
  }

  Future<void> _handleEndOfSurah() async {
    final s = state;
    // Sleep timer set to end-of-surah: stop instead of repeating/continuing.
    if (_sleepStopAtSurahEnd) {
      await _pauseAtEndOfSession();
      return;
    }
    // Budget-based repeat: _replayForRepeat() decrements _playsRemaining and
    // returns true when replays remain. When it returns false the budget is
    // exhausted — fall through to mode switch.
    if (_replayForRepeat() &&
        s.reciter != null &&
        s.moshaf != null &&
        s.surah != null) {
      await _load(
        reciter: s.reciter!,
        moshaf: s.moshaf!,
        surah: s.surah!,
        startAyah: s.rangeStart,
        endAyah: s.rangeEnd,
        rangeFrom: s.rangeFrom,
        rangeTo: s.rangeTo,
      );
      return;
    }
    switch (state.mode) {
      case RecitationMode.repeatSelection:
        // Budget exhausted — fall through to stop (repeat count is 1-based:
        // count=N means play N times, not N+1).
        await _pauseAtEndOfSession();
      case RecitationMode.stopAtEnd:
        await _pauseAtEndOfSession();
      case RecitationMode.continueToNextSurah:
        await _playSurahDelta(1);
    }
  }

  /// Pauses playback at the end of a selection/surah while keeping the player
  /// chrome visible.
  Future<void> _pauseAtEndOfSession() async {
    _userStopped = true;
    await _service.pause();
    state = state.copyWith(
      status: RecitationStatus.paused,
      active: true,
      currentAyah: null,
      playbackHighlightAyah: null,
    );
  }

  Future<void> _bootstrapSession() async {
    if (state.reciter != null) return;
    try {
      final reciter = await ref.read(selectedReciterProvider.future);
      final moshaf = await ref.read(selectedMoshafProvider.future);
      if (reciter == null || moshaf == null) return;
      final settings = ref.read(recitationSettingsProvider).value;
      state = state.copyWith(
        active: true,
        reciter: reciter,
        moshaf: moshaf,
        surah: settings?.lastSurah,
        rangeStart: settings?.lastRangeStart,
        rangeEnd: settings?.lastRangeEnd,
        rangeFrom: settings?.lastRangeFromSurah != null &&
                settings?.lastRangeFromAyah != null
            ? AyahReference(
                surah: settings!.lastRangeFromSurah!,
                ayah: settings.lastRangeFromAyah!,
              )
            : null,
        rangeTo: settings?.lastRangeToSurah != null &&
                settings?.lastRangeToAyah != null
            ? AyahReference(
                surah: settings!.lastRangeToSurah!,
                ayah: settings.lastRangeToAyah!,
              )
            : null,
      );
    } on Object catch (error, stack) {
      ref
          .read(loggerProvider)
          .w(
            'Recitation session bootstrap failed',
            error: error,
            stackTrace: stack,
          );
    }
  }

  Future<bool> _safeSeek(int posMs, {int? generation}) async {
    if (generation != null && generation != _loadGeneration) return false;
    if (_service.state is PlaybackIdle && state.surah == null) return false;
    final ok = await _service.safeSeek(Duration(milliseconds: posMs));
    if (!ok) {
      ref.read(loggerProvider).w('Recitation seek failed at ${posMs}ms');
    }
    return ok;
  }

  /// Consumes one repeat from the budget. Returns true if the selection should
  /// replay (budget had more than one play left).
  bool _replayForRepeat() {
    if (_playsRemaining > 1) {
      _playsRemaining -= 1;
      return true;
    }
    return false;
  }

  void _resetTiming() {
    _timing = null;
    _rangeStartMs = null;
    _rangeEndMs = null;
    _abLoopActive = false;
    _abLoopExhausted = false;
    _ayahCache.clear();
    unawaited(_service.setAbLoopA(null));
    unawaited(_service.setAbLoopB(null));
    unawaited(_service.setLoop(Loop.off));
  }

  void _refreshSleepEndOfAyah(int ayahNumber) {
    if (state.sleep != RecitationSleep.endOfAyah) return;
    _sleepDeadlineMs = _timing?.forAyah(ayahNumber)?.endMs;
  }

  String _surahTitle(int surah) =>
      _mushaf.getSurahSync(surah)?.displayName ?? 'Surah $surah';
}

class _SuspendedRecitation {
  const _SuspendedRecitation({
    required this.reciter,
    required this.moshaf,
    required this.surah,
    required this.rangeStart,
    required this.rangeEnd,
    required this.rangeFrom,
    required this.rangeTo,
    required this.positionMs,
    required this.wasPlaying,
  });

  final Reciter reciter;
  final Moshaf moshaf;
  final int surah;
  final int? rangeStart;
  final int? rangeEnd;
  final AyahReference? rangeFrom;
  final AyahReference? rangeTo;
  final int positionMs;
  final bool wasPlaying;
}
