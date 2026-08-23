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
import 'package:tawaq/core/utils/cancellation_token.dart';
import 'package:tawaq/feature/quran/data/repository/recitation_repository.dart';
import 'package:tawaq/feature/quran/data/sources/mp3quran_api.dart';
import 'package:tawaq/feature/quran/data/sources/recitation_cache.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_settings.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/domain/recitation/recitation_session.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_reference_logic.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_playback_policy.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_range.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_seek_pipeline.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_state_machine.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_timeline.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';

part 'recitation_provider.g.dart';

@Riverpod(keepAlive: true)
http.Client recitationHttpClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
}

@Riverpod(keepAlive: true)
RecitationCache recitationCache(Ref ref) => RecitationCache(
  client: ref.watch(recitationHttpClientProvider),
  logger: ref.watch(loggerProvider),
);

/// Recitation repository (API + on-disk cache).
@Riverpod(keepAlive: true)
RecitationRepository recitationRepository(Ref ref) {
  final client = ref.watch(recitationHttpClientProvider);
  return RecitationRepository(
    api: Mp3QuranApi(client: client, logger: ref.watch(loggerProvider)),
    cache: ref.watch(recitationCacheProvider),
    logger: ref.watch(loggerProvider),
  );
}

/// The reciter catalog (timing links merged), cached on disk.
@Riverpod(keepAlive: true)
Future<List<Reciter>> reciters(Ref ref) =>
    ref.watch(recitationRepositoryProvider).reciters();

/// Runtime state owned by [RecitationOfflineStore].
class RecitationOfflineState {
  const RecitationOfflineState({
    this.files = const [],
    this.totalBytes = 0,
    this.saveProgress,
    this.error,
  });

  final List<CachedRecitation> files;
  final int totalBytes;
  final OfflineSaveSnapshot? saveProgress;
  final String? error;

  RecitationOfflineState copyWith({
    List<CachedRecitation>? files,
    int? totalBytes,
    OfflineSaveSnapshot? saveProgress,
    bool clearProgress = false,
    String? error,
    bool clearError = false,
  }) => RecitationOfflineState(
    files: files ?? this.files,
    totalBytes: totalBytes ?? this.totalBytes,
    saveProgress: clearProgress ? null : saveProgress ?? this.saveProgress,
    error: clearError ? null : error ?? this.error,
  );
}

/// The only writable authority for cached files and offline operation state.
@Riverpod(keepAlive: true)
class RecitationOfflineStore extends _$RecitationOfflineStore {
  @override
  Future<RecitationOfflineState> build() => _scan();

  Future<RecitationOfflineState> _scan() async {
    final files = await ref.read(recitationCacheProvider).listCached();
    return RecitationOfflineState(
      files: List.unmodifiable(files),
      totalBytes: files.fold<int>(0, (sum, file) => sum + file.sizeBytes),
    );
  }

  Future<void> refresh() async {
    final scanned = await _scan();
    if (!ref.mounted) return;
    state = AsyncData(
      scanned.copyWith(
        saveProgress: state.value?.saveProgress,
        error: state.value?.error,
      ),
    );
  }

  Future<void> delete(String path) async {
    await ref.read(recitationCacheProvider).deleteCached(path);
    await refresh();
  }

  void setProgress(OfflineSaveSnapshot progress) {
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(saveProgress: progress));
    }
  }

  void clearProgress() {
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(clearProgress: true));
    }
  }

  /// Resets transient state before an explicit save or retry begins.
  void beginSave() {
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        current.copyWith(clearProgress: true, clearError: true),
      );
    }
  }

  void setError(String error) {
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(error: error));
  }

  void clearError() {
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(clearError: true));
  }
}

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

/// Resolved reciter + moshaf from persisted settings (with catalog fallbacks).
typedef SelectedRecitation = ({Reciter reciter, Moshaf moshaf});

/// Read-only composition of recitation session, preferences, and transport.
class RecitationViewState {
  const RecitationViewState({
    required this.session,
    required this.preferences,
    required this.audio,
  });

  final RecitationSessionState session;
  final RecitationSettings preferences;
  final AudioSessionSnapshot audio;

  /// Whether the native transport currently belongs to recitation.
  bool get ownsAudio => audio.owner == kRecitationLeaseOwner;

  /// Native play intent for the recitation lease only.
  bool get isPlaying => ownsAudio && audio.playIntent;

  /// Loading state composed from session preparation and native transport.
  bool get isLoading =>
      session.timelinePending ||
      session.isLoading ||
      (ownsAudio && audio.lifecycle == AudioSessionLifecycle.loading);

  /// Whether the saved recitation selection and Quran reference data are
  /// still loading. This is intentionally separate from audio loading.
  bool get isInitializing => session.isInitializing;

  /// Whether initialization failed and needs an explicit retry.
  bool get hasInitializationError => session.hasInitializationError;

  /// Whether a user action can start playback for the current selection.
  bool get canPlay =>
      session.isInitializationReady &&
      session.reciter != null &&
      session.moshaf != null &&
      session.surah != null;

  /// Whether the current selection has completed.
  bool get isEnded =>
      session.isEnded ||
      (ownsAudio && audio.lifecycle == AudioSessionLifecycle.completed);

  /// Canonical live position, or the frozen session position while preempted.
  Duration get position => ownsAudio ? audio.position : session.position;

  /// Timing-aware duration composed without writing another transport field.
  Duration get duration => ownsAudio && audio.duration > session.duration
      ? audio.duration
      : session.duration;

  /// Seekable ranges for the active recitation lease.
  List<PlaybackBufferRange> get bufferedRanges =>
      ownsAudio ? audio.bufferedRanges : const [];
}

/// Canonical transport view; no field in this provider is writable.
@riverpod
RecitationViewState recitationView(Ref ref) => RecitationViewState(
  session: ref.watch(recitationControllerProvider),
  preferences:
      ref.watch(recitationSettingsProvider).value ??
      RecitationSettings.initial(),
  audio: ref.watch(audioSessionProvider),
);

/// The currently selected reciter and moshaf, falling back to the first timed
/// reciter when no persisted id matches.
@Riverpod(keepAlive: true)
Future<SelectedRecitation?> selectedRecitation(Ref ref) async {
  final reciters = await ref.watch(recitersProvider.future);
  if (reciters.isEmpty) return null;
  final settings = ref.watch(recitationSettingsProvider.select((s) => s.value));
  Reciter? reciter;
  final id = settings?.reciterId;
  if (id != null) {
    for (final r in reciters) {
      if (r.id == id) {
        reciter = r;
        break;
      }
    }
  }
  if (reciter == null) {
    for (final r in reciters) {
      if (r.hasTiming) {
        reciter = r;
        break;
      }
    }
    reciter ??= reciters.first;
  }
  final moshaf = reciter.resolveMoshaf(settings?.moshafId);
  if (moshaf == null) return null;
  return (reciter: reciter, moshaf: moshaf);
}

/// Shows a toast when [RecitationState.error] is set.
class RecitationErrorToastListener extends ConsumerWidget {
  /// Creates [RecitationErrorToastListener].
  const RecitationErrorToastListener({required this.child, super.key});

  /// Wrapped shell content.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(recitationControllerProvider.select((p) => p.error), (
      previous,
      next,
    ) {
      if (next == null || next == previous) return;
      showFToast(
        context: context,
        variant: .destructive,
        icon: const Icon(FLucideIcons.triangleAlert),
        title: Text(context.l10n.quranRecitationPlaybackFailed(next)),
      );
      ref.read(recitationControllerProvider.notifier).clearError();
    });
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
/// Riverpod adapter for the framework-independent [RecitationSession].
///
/// The session is the only writer of logical recitation state. This adapter
/// translates UI and native audio input, then executes the resulting I/O.
@Riverpod(keepAlive: true)
class RecitationController extends _$RecitationController {
  static const _seekLogPrefix = 'tawaq.recitation.seek';

  String _surahTitle(int surah) => _surahName(surah);

  String _surahFileName(int surah) {
    // Cache paths must survive locale changes and continue to find files
    // created by previous versions, which used the Arabic-first display name.
    return _mushaf.getSurahSync(surah)?.displayName ?? surah.toString();
  }

  String _surahName(int surah) {
    final locale = ref.read(localeProvider).value ?? 'en';
    return AyahReferenceLogic.surahName(
      _mushaf.getSurahSync(surah),
      surah,
      preferArabic: locale == 'ar',
      fallbackName: '',
    );
  }

  RecitationSession? _sessionInstance;
  RecitationTimeline? _timelineForTest;
  Timer? _sleepTimer;
  bool _sessionBootstrapped = false;
  int _initializationGeneration = 0;
  CancellationToken? _downloadToken;
  CancellationToken? _offlineSaveToken;
  Future<void> _effectsTail = Future<void>.value();

  RecitationSession get _session =>
      _sessionInstance ??= _createSession(initialState: state);

  RecitationSession _createSession({
    RecitationState initialState = const RecitationState(active: true),
  }) {
    final session = RecitationSession(
      initialState: initialState,
      surahAyahCount: (surah) => _mushaf.getSurahSync(surah)?.ayahCount ?? 1,
      onStateChanged: (next) => state = next,
      log: _seekLog,
    );
    final testTimeline = _timelineForTest;
    if (testTimeline != null) session.replaceTimelineForTest(testTimeline);
    return session;
  }

  late final SeekPipeline _seekPipeline = SeekPipeline(
    log: _seekLog,
    seek: (position) async {
      // Never seek after AlertSuspend released the lease (idle reacquire race).
      if (_session.state.suspendedSnapshot != null) return false;
      return _service.seek(position, owner: kRecitationLeaseOwner);
    },
    onSeekFailed: ({required revertTo, required failedTarget}) {
      _revertPendingSeek(revertTo, onlyIfPendingEquals: failedTarget);
    },
    onTimeout: ({required revertTo}) {
      _revertPendingSeek(revertTo);
    },
    lastAcceptedPosition: () => _session.lastAcceptedPosition,
    hasPendingSeek: () => _session.state.pendingSeekTarget != null,
  );

  @override
  RecitationState build() {
    _sessionInstance ??= _createSession(
      initialState: const RecitationState(
        active: true,
        initializationStatus: RecitationInitializationStatus.initializing,
      ),
    );
    ref
      ..onDispose(() {
        _persistPlaybackCheckpoint();
        _sleepTimer?.cancel();
        _seekPipeline.dispose();
      })
      ..listen(audioSessionProvider, _onAudioSessionChanged)
      ..listen(
        recitationSettingsProvider.select(
          (s) => (s.value?.ayahRepeatCount, s.value?.rangeRepeatCount),
        ),
        (previous, next) {
          if (next.$1 == null && next.$2 == null) return;
          if (next == previous) return;
          _session.updateRepeatDefaults(
            ayahRepeatCount: next.$1,
            rangeRepeatCount: next.$2,
          );
          _dispatch(
            SetRepeatCounts(
              ayahRepeatCount: next.$1,
              rangeRepeatCount: next.$2,
            ),
          );
        },
      );

    if (_sessionBootstrapped) {
      // Preserve in-flight session across rare rebuilds.
      return _session.state;
    }
    _sessionBootstrapped = true;
    unawaited(Future.microtask(_initializeSession));
    return _session.state;
  }

  RecitationRepository get _repo => ref.read(recitationRepositoryProvider);
  TawaqAudioService get _service => ref.read(tawaqAudioServiceProvider);
  MushafReaderController get _mushaf => ref.read(quranMushafControllerProvider);

  /// The timing map for the loaded surah, or null when unavailable.
  SurahTiming? get currentTiming => _session.currentTiming;

  /// Whether per-ayah timing is loaded for the current surah.
  bool get hasAyahTiming => _session.hasAyahTiming;

  /// Injects [timeline] for tests of [goToPlaybackInMushaf].
  @visibleForTesting
  set timelineForTest(RecitationTimeline timeline) {
    _timelineForTest = timeline;
    _sessionInstance?.replaceTimelineForTest(timeline);
  }

  /// Cancels the in-flight surah download, if one is active.
  ///
  /// The download stream observes its cancellation token and deletes the
  /// partial `.part` file; resolveSurahUri then falls back to the network
  /// URL (or a usable `.part`) and playback proceeds.
  Future<void> cancelDownload() async {
    _downloadToken?.cancel();
  }

  /// Cancels an in-flight explicit offline save, if one is active.
  Future<void> cancelOfflineSave() async {
    _offlineSaveToken?.cancel();
  }

  /// Downloads the currently loaded surah into the offline cache.
  ///
  /// No-ops when there is no active surah or the file is already cached.
  /// Does not interrupt playback. If an auto-save download for the same
  /// surah is already in flight, joins it rather than silently returning.
  Future<void> saveCurrentSurahOffline() async {
    final reciter = state.reciter;
    final moshaf = state.moshaf;
    final surah = state.surah;
    if (reciter == null || moshaf == null || surah == null) return;

    final surahName = _surahFileName(surah);
    final alreadyCached = await _repo.isSurahCached(
      reciter: reciter,
      moshaf: moshaf,
      surah: surah,
      surahName: surahName,
    );
    if (alreadyCached) {
      _invalidateCachedRecitations();
      return;
    }

    _offlineSaveToken?.cancel();
    final token = CancellationToken();
    _offlineSaveToken = token;
    ref.read(recitationOfflineStoreProvider.notifier).beginSave();

    var failed = false;
    Object? failure;
    try {
      await _repo.saveSurahAudio(
        reciter: reciter,
        moshaf: moshaf,
        surah: surah,
        surahName: surahName,
        cancellationToken: token,
        onProgress: (p) {
          ref
              .read(recitationOfflineStoreProvider.notifier)
              .setProgress(
                OfflineSaveSnapshot(
                  reciterId: reciter.id,
                  moshafId: moshaf.id,
                  surah: surah,
                  progress: p,
                ),
              );
        },
      );
    } on Object catch (error, stack) {
      failed = true;
      failure = error;
      ref
          .read(loggerProvider)
          .w(
            'Offline save failed for surah $surah',
            error: error,
            stackTrace: stack,
          );
    } finally {
      if (identical(_offlineSaveToken, token)) {
        _offlineSaveToken = null;
        ref.read(recitationOfflineStoreProvider.notifier).clearProgress();
      }
    }

    if (!token.isCancelled && !failed) {
      final saved = await _repo.isSurahCached(
        reciter: reciter,
        moshaf: moshaf,
        surah: surah,
        surahName: surahName,
      );
      if (saved) {
        await ref.read(recitationOfflineStoreProvider.notifier).refresh();
      }
    } else if (failed && !token.isCancelled) {
      ref.read(recitationOfflineStoreProvider.notifier).setError('$failure');
    }
  }

  void _invalidateCachedRecitations() {
    unawaited(ref.read(recitationOfflineStoreProvider.notifier).refresh());
  }

  /// Invalidates cache listings when a resolve just downloaded a local file.
  void _invalidateIfDownloaded({
    required String uri,
    required Stream<DownloadProgress>? progress,
    required Reciter reciter,
    required Moshaf moshaf,
    required int surah,
  }) {
    if (progress != null && uri.startsWith('file://')) {
      _invalidateCachedRecitations();
    }
  }

  // ---- Public controls ---------------------------------------------------

  /// Plays the whole [surah] for [reciter]/[moshaf] from the beginning.
  Future<void> playSurah({
    required Reciter reciter,
    required Moshaf moshaf,
    required int surah,
  }) async {
    _acceptUserSelection();
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
    _acceptUserSelection();
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
    _acceptUserSelection();
    final segment = firstSegmentForRange(from: from, to: to, mushaf: _mushaf);
    _dispatch(
      PlayRange(
        reciter: reciter,
        moshaf: moshaf,
        from: AyahReference(surah: segment.surah, ayah: segment.startAyah),
        to: AyahReference(surah: segment.surah, ayah: segment.endAyah),
        globalFrom: from,
        globalTo: to,
        openEnded: to == null,
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
    _acceptUserSelection();
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
            // Keep dialog endpoints so reopening restores 1..ayahCount (or
            // continue-from-here start) instead of collapsing to ayah 1.
            persistRangeFrom: from,
            persistRangeTo: to,
          ),
        );
      case PlayAyahRangeIntent(:final resumeFrom):
        if (!moshaf.hasTiming &&
            !rangePlayableWithoutTiming(intent.from, intent.to, _mushaf)) {
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
            from: AyahReference(surah: segment.surah, ayah: segment.startAyah),
            to: AyahReference(surah: segment.surah, ayah: segment.endAyah),
            globalFrom: intent.from,
            globalTo: intent.to,
            resumeFrom: resumeFrom,
            openEnded: intent.to == null,
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
      final autoHighlight = ref
          .read(recitationSettingsProvider.notifier)
          .setReciter(
            reciterId: reciter.id,
            moshafId: moshaf.id,
            moshafName: moshaf.name,
          );
      _acceptUserSelection(reciter: reciter, moshaf: moshaf);
      return autoHighlight;
    }

    // Drop stale timing immediately so position ticks cannot highlight ayahs
    // from the previous moshaf while the new load is in flight.
    _session.discardTimeline();

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
          openEnded: s.rangeTo == null,
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
    if (!state.isInitializationReady) return;
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
  void clearError() => _session.clearError();

  /// Retries restoring the saved selection and Quran reference data.
  Future<void> retryInitialization() => _initializeSession();

  /// Moves the mushaf to the current playback location.
  ///
  /// Untimed reciters open the playing surah's start page. Timed reciters jump
  /// to the current ayah and select it, ignoring highlight/auto-scroll toggles.
  Future<void> goToPlaybackInMushaf() async {
    final s = state;
    final surah = s.surah;
    if (surah == null) return;

    if (s.moshaf?.hasTiming == true) {
      final ayahNumber = s.currentAyah ?? _session.timeline.ayahAt(s.position);
      if (ayahNumber != null) {
        try {
          final ayah = await mushafAyahOrNull(_mushaf, surah, ayahNumber);
          if (ayah == null) return;
          ref.read(quranSelectedAyahIdProvider.notifier).select(ayah.ayahId);
          await _scrollToAyah(ayah.ayahId, select: true);
        } on Object catch (error, stack) {
          ref
              .read(loggerProvider)
              .w(
                'Go to playback mushaf failed',
                error: error,
                stackTrace: stack,
              );
        }
        return;
      }
    }

    ref.read(quranSelectedAyahIdProvider.notifier).select(null);
    _mushaf.clearSelection();
    await _scrollToSurahWhenReady(surah);
  }

  /// Stops audio but keeps the player session visible.
  Future<void> stop() async {
    _dispatch(const Stop());
  }

  /// Seeks within the current surah audio.
  ///
  /// The seek bar snaps to ayah starts before calling this; the session
  /// reconciles repeat/loop/highlight state via [SeekPipeline].
  Future<void> seekTo(Duration position) async {
    _seekLog(
      'seekTo entry targetMs=${position.inMilliseconds} '
      'posMs=${state.position.inMilliseconds} '
      'pendingMs=${state.pendingSeekTarget?.inMilliseconds} '
      'loadGen=${state.loadGeneration}',
    );
    await _seekSession(position);
  }

  /// Advances to the next ayah within the current surah/range.
  Future<void> skipAyahNext() async {
    final current = currentAyahOrGuess(state, _session.timeline);
    if (current == null) return;
    final last = lastPlayableAyah(state, _session.timeline);
    if (last == null || current >= last) return;
    await _navigateToAyahSession(current + 1);
  }

  /// Goes to the previous ayah within the current surah/range.
  Future<void> skipAyahPrevious() async {
    final current = currentAyahOrGuess(state, _session.timeline);
    if (current == null) return;
    final first = firstPlayableAyah(state);
    if (current <= first) return;
    await _navigateToAyahSession(current - 1);
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

  /// Applies volume to the audio engine during slider drag (not persisted).
  Future<void> setVolumePreview(double volume) async {
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

    _session.setSleep(sleep);
  }

  // ---- Alert coordination ------------------------------------------------

  /// Captures recitation state and releases the player for an alert.
  ///
  /// Yields for playing/paused/buffering/loading sessions and whenever this
  /// controller still holds the audio lease, so adhan never blocks forever on
  /// [AudioLeaseRegistry.acquire]. Bumps [RecitationState.loadGeneration] so
  /// an in-flight [_load] cannot re-steal the lease after release.
  ///
  /// Pause/release run on the I/O mutex after prior seeks drain; pipeline
  /// clear inside that section invalidates deferred/in-flight seeks so they
  /// cannot reposition the engine after [ReleaseAudioLease].
  Future<void> suspendForAlert() async {
    if (state.suspendedSnapshot != null) return;

    final holdsLease = _service.currentLeaseOwner == kRecitationLeaseOwner;
    final activeSession =
        state.surah != null &&
        state.reciter != null &&
        (state.isPlaying ||
            state.isPaused ||
            state.isBuffering ||
            state.isLoading);

    if (!holdsLease && !activeSession) return;

    if (state.surah == null || state.reciter == null) {
      // Lease without a resumable session — free the engine for adhan.
      if (holdsLease) {
        await _enqueueIo(() async {
          _seekPipeline.clear();
          await _service.pause(owner: kRecitationLeaseOwner);
          await _service.release(owner: kRecitationLeaseOwner);
        });
      }
      return;
    }

    final settings = ref.read(recitationSettingsProvider).value;
    final ayahRepeatCount = clampRepeatCount(settings?.ayahRepeatCount ?? 1);
    final rangeRepeatCount = clampRepeatCount(settings?.rangeRepeatCount ?? 1);
    _session.updateRepeatDefaults(
      ayahRepeatCount: ayahRepeatCount,
      rangeRepeatCount: rangeRepeatCount,
    );
    final decision = _session.dispatch(const AlertSuspend());
    _applySessionDecision(decision, runIo: false);
    // Drain in-flight seeks, then clear+pause+release in one critical section.
    await _enqueueIo(() async {
      _seekPipeline.clear();
      if (state.suspendedSnapshot == null) return;
      await _service.pause(owner: kRecitationLeaseOwner);
      await _service.release(owner: kRecitationLeaseOwner);
    });
  }

  /// Resumes recitation from the saved position once the alert ends.
  ///
  /// Always goes through [AlertResume] → [_load] / [LoadRange]. There is no
  /// URI-match fast path — gapless and native file-loop sessions would leave
  /// stale engine state if we only `openAndSeekTo` the last URI.
  Future<void> resumeAfterAlert() async {
    if (state.suspendedSnapshot == null) return;
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
    final settings = ref.read(recitationSettingsProvider).value;
    final ayahRepeatCount = clampRepeatCount(settings?.ayahRepeatCount ?? 1);
    final rangeRepeatCount = clampRepeatCount(settings?.rangeRepeatCount ?? 1);
    _session.updateRepeatDefaults(
      ayahRepeatCount: ayahRepeatCount,
      rangeRepeatCount: rangeRepeatCount,
    );
    final decision = _session.dispatch(
      event,
      trackLoaded: trackLoaded,
      nativePlayWhenReady: nativePlayWhenReady,
    );
    _applySessionDecision(decision);
  }

  void _applySessionDecision(
    RecitationSessionDecision decision, {
    bool runIo = true,
  }) {
    if (decision.abandonsPendingSeek) {
      _seekPipeline.clear();
    } else {
      _seekPipeline.syncTimeout();
    }
    _applyLocalSideEffects(decision.effects);
    if (!runIo) return;
    final ioEffects = decision.effects
        .where(
          (effect) =>
              effect is! CancelSleepTimer && effect is! PersistPlaybackState,
        )
        .toList(growable: false);
    unawaited(_applyEffects(ioEffects));
  }

  /// Reverts optimistic seek UI when the engine never lands near the target.
  ///
  /// When [onlyIfPendingEquals] is set (engine seek failure), only clears if
  /// pending still matches that failed target — an older seek must not wipe a
  /// newer scrub/skip pending.
  void _revertPendingSeek(Duration revertTo, {Duration? onlyIfPendingEquals}) {
    final reverted = _session.revertPendingSeek(
      revertTo,
      onlyIfPendingEquals: onlyIfPendingEquals,
    );
    if (reverted) _seekPipeline.clear();
  }

  /// Intentional in-track / scrub-during-load seek (no Seek event).
  Future<void> _seekSession(Duration position) async {
    if (state.suspendedSnapshot != null) return;
    final defer = state.isLoading;
    if (defer || state.timelinePending) {
      final target = _session.prepareSeek(position);
      _seekPipeline.syncTimeout();
      await _enqueueIo(() async {
        // PlaySurah/Stop/AlertSuspend/newer seek abandoned this scrub.
        if (state.suspendedSnapshot != null) return;
        if (state.pendingSeekTarget != target) return;
        await _seekPipeline.request(
          target,
          mode: state.isLoading
              ? SeekRequestMode.deferUntilLoaded
              : SeekRequestMode.inTrack,
        );
      });
      return;
    }

    final clamped = _session.timeline.clampToRange(position);
    final ayah = _session.timeline.ayahAt(clamped);
    if (ayah != null && _session.timeline.startOfAyah(ayah) != null) {
      await _navigateToAyahSession(ayah);
      return;
    }

    final target = _session.prepareSeek(clamped);
    _seekPipeline.syncTimeout();
    await _enqueueIo(() async {
      if (state.suspendedSnapshot != null) return;
      if (state.pendingSeekTarget != target) return;
      await _seekPipeline.request(
        target,
        mode: state.isLoading
            ? SeekRequestMode.deferUntilLoaded
            : SeekRequestMode.inTrack,
      );
    });
  }

  /// Snap/skip to an ayah start and re-arm A-B when needed.
  Future<void> _navigateToAyahSession(int targetAyah) async {
    final navigation = _session.prepareAyahNavigation(targetAyah);
    if (navigation == null) return;
    final start = navigation.position;
    final ayahRepeatCount = state.ayahRepeatCount;
    _seekPipeline.syncTimeout();

    await _enqueueIo(() async {
      // PlaySurah/Stop/AlertSuspend/newer seek abandoned this navigation.
      if (state.suspendedSnapshot != null) return;
      if (state.pendingSeekTarget != start) return;
      await _seekPipeline.request(
        start,
        mode: state.isLoading
            ? SeekRequestMode.deferUntilLoaded
            : SeekRequestMode.inTrack,
      );
      // Landing may have cleared pending; still finish A-B / highlight for
      // this navigation unless a newer pending target replaced ours.
      if (state.suspendedSnapshot != null) return;
      final pending = state.pendingSeekTarget;
      if (pending != null && pending != start) return;
      if (navigation.needsAbLoop) {
        await _setAyahLoop(targetAyah, ayahRepeatCount);
      }
    });
  }

  /// Sleep cancel / persist — local side effects, not audio I/O.
  ///
  /// [HighlightAyah] stays on the serialized I/O path so it runs after
  /// [SeekAudio] / [LoadAyahLoop] in advance-after-ayah-loop batches.
  void _applyLocalSideEffects(List<RecitationEffect> effects) {
    for (final effect in effects) {
      switch (effect) {
        case CancelSleepTimer():
          _sleepTimer?.cancel();
          _sleepTimer = null;
        case PersistPlaybackState():
          final notifier = ref.read(recitationSettingsProvider.notifier);
          if (effect.positionMs != null && effect.surah != null) {
            notifier.persistPlaybackCheckpoint(
              surah: effect.surah!,
              positionMs: effect.positionMs!,
              rangeFromSurah: effect.rangeFromSurah,
              rangeFromAyah: effect.rangeFromAyah,
              rangeToSurah: effect.rangeToSurah,
              rangeToAyah: effect.rangeToAyah,
            );
          } else {
            notifier.setPlaybackState(
              surah: effect.surah,
              rangeFromSurah: effect.rangeFromSurah,
              rangeFromAyah: effect.rangeFromAyah,
              rangeToSurah: effect.rangeToSurah,
              rangeToAyah: effect.rangeToAyah,
            );
          }
        default:
          break;
      }
    }
  }

  /// Shared I/O mutex for machine effects and UI session seeks/skips.
  Future<void> _enqueueIo(Future<void> Function() work) {
    return _effectsTail = chainEffectsTail(_effectsTail, work);
  }

  Future<void> _applyEffects(List<RecitationEffect> effects) {
    // Serialize effect batches so concurrent dispatches cannot interleave
    // load/seek/pause side effects (same mutex as [_seekSession]).
    return _enqueueIo(() => _runEffects(effects));
  }

  Future<void> _runEffects(List<RecitationEffect> effects) async {
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
          await _service.pause(owner: kRecitationLeaseOwner);
          _persistPlaybackCheckpoint();
        case ReleaseAudioLease():
          await _service.release(owner: kRecitationLeaseOwner);
        case ResumeAudio():
          await _service.resume(owner: kRecitationLeaseOwner);
          final resumeSurah = state.surah;
          final resumeReciter = state.reciter;
          if (resumeSurah != null && resumeReciter != null) {
            await _publishRecitationMediaSession(
              surah: resumeSurah,
              reciterName: resumeReciter.name,
            );
          }
        case StopAudio():
          await _service.stop(
            fadeOut: kAudioDefaultFadeOut,
            owner: kRecitationLeaseOwner,
          );
        case SeekAudio():
          // AlertSuspend clears pending and sets suspendedSnapshot; skip so we
          // never seek after ReleaseAudioLease / lease reacquire races.
          if (state.suspendedSnapshot != null) break;
          await _seekPipeline.request(
            effect.position,
            mode: state.isLoading
                ? SeekRequestMode.deferUntilLoaded
                : SeekRequestMode.inTrack,
          );
        case LoadAyahLoop():
          if (state.suspendedSnapshot != null) break;
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
          if (state.suspendedSnapshot != null) break;
          await _setAyahLoop(ayah, repeatCount);
        // Runs on the I/O path after SeekAudio / LoadAyahLoop in the same batch.
        case HighlightAyah():
          // QuranScreen projects playback highlights while it is mounted.
          break;
        // Peeled off in [_applyLocalSideEffects] before I/O runs.
        case CancelSleepTimer():
        case PersistPlaybackState():
          break;
      }
    }

    for (final effect in effects) {
      final deferAfterLoad =
          hasLoad &&
          (effect is SetNativeLoop ||
              effect is LoadAyahLoop ||
              effect is RefreshAbLoop ||
              effect is PauseAudio);
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

  void _persistPlaybackCheckpoint() {
    final s = state;
    if (s.surah == null || s.userStopped || s.isEnded) return;

    Duration position;
    if (s.moshaf?.hasTiming == true && s.currentAyah != null) {
      position = _session.timeline.startOfAyah(s.currentAyah!) ?? s.position;
    } else {
      position = s.position;
    }
    if (position <= Duration.zero) return;

    ref
        .read(recitationSettingsProvider.notifier)
        .persistPlaybackCheckpoint(
          surah: s.surah!,
          positionMs: position.inMilliseconds,
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
    final newGen = _session.beginLoad(hasTiming: moshaf.hasTiming);

    try {
      await _service.stop(owner: kRecitationLeaseOwner);
    } on Object catch (error, stack) {
      ref
          .read(loggerProvider)
          .d(
            'Audio stop during load failed (continuing): $error',
            stackTrace: stack,
          );
    }
    final isRange = startAyah != null && endAyah != null;
    final localStart = startAyah;
    final localEnd = endAyah;
    final isUntimedFullSurah =
        isRange &&
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
      _session.setAudioError('No timing data for range playback');
      _seekPipeline.clear();
      return;
    }

    // Await hydration so auto-save respects the user's persisted preference
    // instead of defaulting to persist:true while settings are still loading.
    final settings = await ref.read(recitationSettingsProvider.future);
    if (newGen != state.loadGeneration) return;
    final volume = settings.volume;
    final ayahRepeatCount = clampRepeatCount(settings.ayahRepeatCount);
    final persist = settings.autoSaveRecitations;

    final token = _startDownload();
    final resolved = await _repo.resolveSurahUri(
      reciter: reciter,
      moshaf: moshaf,
      surah: surah,
      surahName: _surahFileName(surah),
      persist: persist,
      cancellationToken: token,
      onProgress: (p) =>
          ref.read(recitationDownloadProgressProvider.notifier).progress = p,
    );
    _finishDownload(token);
    if (newGen != state.loadGeneration) return;
    _invalidateIfDownloaded(
      uri: resolved.uri,
      progress: resolved.progress,
      reciter: reciter,
      moshaf: moshaf,
      surah: surah,
    );

    if (moshaf.hasTiming) {
      final timing = await _repo.timing(surah, moshaf.timingReadId!);
      if (newGen != state.loadGeneration) return;
      _session.installTimeline(timelineFor(state, timing), generation: newGen);
    }

    final localStartAyah = startAyah;
    final localEndAyah = endAyah;
    if (isRange && moshaf.hasTiming) {
      if (localStartAyah == null ||
          localEndAyah == null ||
          _session.timeline.timing == null ||
          _session.timeline.startOfAyah(localStartAyah) == null ||
          _session.timeline.endOfAyah(localEndAyah) == null) {
        _session.setAudioError('Ayah timing unavailable');
        _seekPipeline.clear();
        return;
      }
    }

    final seekTo =
        resumeFrom ??
        (isRange && !isUntimedFullSurah && localStartAyah != null
            ? _session.timeline.startOfAyah(localStartAyah)
            : null) ??
        Duration.zero;

    if (newGen != state.loadGeneration || state.suspendedSnapshot != null) {
      return;
    }

    final uriScheme = resolved.uri.startsWith('file://') ? 'file' : 'http';
    _seekLog(
      '_load openAndSeekTo surah=$surah uriScheme=$uriScheme '
      'seekToMs=${seekTo.inMilliseconds} loadGen=$newGen',
    );

    await _service.setVolume(volume);
    if (newGen != state.loadGeneration || state.suspendedSnapshot != null) {
      return;
    }
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
    if (newGen != state.loadGeneration || state.suspendedSnapshot != null) {
      return;
    }

    await _publishRecitationMediaSession(
      surah: surah,
      reciterName: reciter.name,
    );

    if (moshaf.hasTiming && ayahRepeatCount > 1) {
      _session.resetAbLoopObservation();
      final firstAyah = isRange ? localStartAyah! : 1;
      await _setAyahLoop(firstAyah, ayahRepeatCount);
    }

    if (newGen == state.loadGeneration) {
      await _seekPipeline.flushDeferred();
    }
  }

  Future<void> _setAyahLoop(int ayah, int ayahRepeatCount) async {
    final start = _session.timeline.startOfAyah(ayah);
    final end = _session.timeline.endOfAyah(ayah);
    if (start == null || end == null) return;
    _session.resetAbLoopObservation();
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
      _session.setRangeEnded();
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
      surahName: _surahFileName(toSurah),
    );
    if (!nextCached) {
      // Fall back to the normal reload path when the next surah is not yet
      // downloaded.
      await _load(reciter: reciter, moshaf: moshaf, surah: toSurah);
      return;
    }

    final newGen = _session.beginGaplessLoad(hasTiming: moshaf.hasTiming);

    final settings = await ref.read(recitationSettingsProvider.future);
    if (newGen != state.loadGeneration) return;
    final persist = settings.autoSaveRecitations;
    final token = _startDownload();
    final currentResolved = await _repo.resolveSurahUri(
      reciter: reciter,
      moshaf: moshaf,
      surah: fromSurah,
      surahName: _surahFileName(fromSurah),
      persist: persist,
      cancellationToken: token,
      onProgress: (p) =>
          ref.read(recitationDownloadProgressProvider.notifier).progress = p,
    );
    if (newGen != state.loadGeneration) {
      _finishDownload(token);
      return;
    }
    _invalidateIfDownloaded(
      uri: currentResolved.uri,
      progress: currentResolved.progress,
      reciter: reciter,
      moshaf: moshaf,
      surah: fromSurah,
    );

    final nextResolved = await _repo.resolveSurahUri(
      reciter: reciter,
      moshaf: moshaf,
      surah: toSurah,
      surahName: _surahFileName(toSurah),
      persist: persist,
      cancellationToken: token,
      onProgress: (p) =>
          ref.read(recitationDownloadProgressProvider.notifier).progress = p,
    );
    _finishDownload(token);
    if (newGen != state.loadGeneration) return;
    _invalidateIfDownloaded(
      uri: nextResolved.uri,
      progress: nextResolved.progress,
      reciter: reciter,
      moshaf: moshaf,
      surah: toSurah,
    );

    SurahTiming? timing;
    if (moshaf.hasTiming) {
      timing = await _repo.timing(toSurah, moshaf.timingReadId!);
      if (newGen != state.loadGeneration) return;
    }

    final bookkeeping = gaplessContinuationBookkeeping(
      nextUri: nextResolved.uri,
      stateForTimeline: state,
      nextTiming: timing,
    );
    if (timing != null) {
      _session.installTimeline(bookkeeping.timeline, generation: newGen);
    }

    final currentTrack = AudioTrack.network(
      id: 'recitation-${reciter.id}-$fromSurah',
      title: _surahTitle(fromSurah),
      url: currentResolved.uri,
      subtitle: reciter.name,
    );
    final nextTrack = AudioTrack.network(
      id: 'recitation-${reciter.id}-$toSurah',
      title: _surahTitle(toSurah),
      url: nextResolved.uri,
      subtitle: reciter.name,
    );

    // Seed previous index below openAtIndex so GaplessTrackAdvanced still
    // fires when openAll starts already at that index (no currentIndex tick).
    _session.seedTrackIndex(bookkeeping.seededTrackIndex);
    await _service.openAll(
      [currentTrack, nextTrack],
      index: bookkeeping.openAtIndex,
      owner: kRecitationLeaseOwner,
    );
    if (newGen != state.loadGeneration) return;
    await _publishRecitationMediaSession(
      surah: toSurah,
      reciterName: reciter.name,
    );
    await _service.setPrefetchPlaylist(true);
    await _service.setGapless(Gapless.yes);

    // openAll may not emit a currentIndex tick when already at openAtIndex.
    // Advance the session explicitly so ayah highlight / media metadata update.
    if (shouldExplicitGaplessAdvance(
      trackIndexAfterOpen: _session.lastTrackIndex,
      seededTrackIndex: bookkeeping.seededTrackIndex,
    )) {
      _session.seedTrackIndex(bookkeeping.openAtIndex);
      _dispatch(GaplessTrackAdvanced(surah: toSurah, ayah: 1));
    }
  }

  void _onAudioSessionChanged(
    AudioSessionSnapshot? previous,
    AudioSessionSnapshot next,
  ) {
    if (next.owner != kRecitationLeaseOwner) return;
    if (_service.currentLeaseOwner != kRecitationLeaseOwner) return;
    final previousNative = previous?.owner == kRecitationLeaseOwner
        ? _nativeSnapshot(previous!)
        : null;
    final decision = _session.observeNative(
      previousNative,
      _nativeSnapshot(next),
    );
    _applySessionDecision(decision);
    if (next.lifecycle == AudioSessionLifecycle.paused &&
        previous?.lifecycle != AudioSessionLifecycle.paused) {
      _persistPlaybackCheckpoint();
    }
  }

  RecitationNativeSnapshot _nativeSnapshot(
    AudioSessionSnapshot snapshot,
  ) => RecitationNativeSnapshot(
    lifecycle: switch (snapshot.lifecycle) {
      AudioSessionLifecycle.idle => RecitationNativeLifecycle.idle,
      AudioSessionLifecycle.loading => RecitationNativeLifecycle.loading,
      AudioSessionLifecycle.buffering => RecitationNativeLifecycle.buffering,
      AudioSessionLifecycle.playing => RecitationNativeLifecycle.playing,
      AudioSessionLifecycle.paused => RecitationNativeLifecycle.paused,
      AudioSessionLifecycle.completed => RecitationNativeLifecycle.completed,
      AudioSessionLifecycle.error => RecitationNativeLifecycle.error,
    },
    position: snapshot.position,
    duration: snapshot.duration,
    playIntent: snapshot.playIntent,
    remainingAbLoops: snapshot.remainingAbLoops,
    playlistIndex: snapshot.playlistIndex,
    error: snapshot.error,
  );

  static const _maxScrollReadyAttempts = 30;

  Future<void> _scrollToAyah(int ayahId, {required bool select}) async {
    await _scrollWhenPageReady(
      () => _mushaf.jumpToAyah(ayahId, select: select),
    );
  }

  Future<void> _scrollToSurahWhenReady(int surah) async {
    await _scrollWhenPageReady(() => _mushaf.jumpToSurah(surah));
  }

  /// Waits for the mushaf page controller to attach, capped so dispose or a
  /// missing page view cannot spin forever on post-frame callbacks.
  Future<void> _scrollWhenPageReady(Future<void> Function() jump) async {
    for (var attempt = 0; attempt < _maxScrollReadyAttempts; attempt++) {
      if (!ref.mounted) return;
      if (_mushaf.pageController.hasClients) {
        await jump();
        return;
      }
      final ready = Completer<void>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!ready.isCompleted) ready.complete();
      });
      await ready.future;
    }
  }

  Future<void> _initializeSession() async {
    final generation = ++_initializationGeneration;
    if (ref.mounted) _session.beginInitialization();
    try {
      final settings = await ref.read(recitationSettingsProvider.future);
      await _mushaf.ensureReady();
      final selected = await ref.read(selectedRecitationProvider.future);
      if (!ref.mounted || generation != _initializationGeneration) return;

      if (selected == null) {
        _session.completeInitialization();
        return;
      }
      final positionMs = settings.lastPlaybackPositionMs;
      _dispatch(
        RecitationSettingsLoaded(
          reciter: selected.reciter,
          moshaf: selected.moshaf,
          surah: settings.lastSurah,
          rangeFrom: _reference(
            settings.lastRangeFromSurah,
            settings.lastRangeFromAyah,
          ),
          rangeTo: _reference(
            settings.lastRangeToSurah,
            settings.lastRangeToAyah,
          ),
          resumeFrom: positionMs != null && positionMs > 0
              ? Duration(milliseconds: positionMs)
              : null,
        ),
      );
    } on Object catch (error, stack) {
      if (!ref.mounted || generation != _initializationGeneration) return;
      ref
          .read(loggerProvider)
          .w(
            'Recitation session bootstrap failed',
            error: error,
            stackTrace: stack,
          );
      _session.failInitialization('$error');
    }
  }

  /// Keeps an in-flight restore from overwriting an explicit user selection.
  void _acceptUserSelection({Reciter? reciter, Moshaf? moshaf}) {
    _initializationGeneration++;
    _session.acceptUserSelection(reciter: reciter, moshaf: moshaf);
  }

  AyahReference? _reference(int? surah, int? ayah) {
    if (surah == null || ayah == null) return null;
    return AyahReference(surah: surah, ayah: ayah);
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

  Future<void> _publishRecitationMediaSession({
    required int surah,
    required String reciterName,
  }) async {
    final l10n = lookupAppLocalizations(
      Locale(ref.read(localeProvider).value ?? 'en'),
    );
    final surahName = AyahReferenceLogic.surahName(
      _mushaf.getSurahSync(surah),
      surah,
      preferArabic: l10n.localeName.startsWith('ar'),
      fallbackName: '',
    );
    await _service.publishMediaSession(
      MediaSessionPublishMetadata(
        title: surahName,
        artist: reciterName,
        appName: l10n.mediaSessionAppName,
        album: l10n.mediaSessionAudioBy('mp3quran.net'),
      ),
    );
  }
}
