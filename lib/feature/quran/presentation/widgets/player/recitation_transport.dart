import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_reference_logic.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_equalizer.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_transport_controls.dart';
import 'package:tawaq/feature/quran/presentation/widgets/surah_name_text.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

export 'package:tawaq/feature/quran/presentation/widgets/player/recitation_transport_controls.dart'
    show SkipAction, SkipControl, leftSkipControl, rightSkipControl;

/// Builds the title-bar play control's complete accessible name and tooltip.
///
/// The caller supplies the already hydrated session projection. This helper
/// intentionally does not read providers or start any asynchronous metadata
/// work while a tooltip is being built.
typedef RecitationTransportPlaybackState = ({
  bool canPlay,
  bool hasInitializationError,
  bool hasMoshaf,
  bool hasRangeSelection,
  bool hasReciter,
  bool hasSurah,
  bool hasTimedReciter,
  bool isEnded,
  bool isInitializing,
  bool isLoading,
  bool isPlaying,
  String? reciterName,
});

/// Projects the exact hydrated view fields needed by the compact transport.
///
/// Keep this projection in sync with [RecitationViewState]; unlike a
/// hand-written fallback it cannot claim a range needs timing when the actual
/// recitation configuration is missing first.
RecitationTransportPlaybackState recitationTransportPlaybackState(
  RecitationViewState view,
) {
  final session = view.session;
  return (
    canPlay: view.canPlay,
    hasInitializationError: view.hasInitializationError,
    hasMoshaf: session.moshaf != null,
    hasRangeSelection: session.hasRangeSelection,
    hasReciter: session.reciter != null,
    hasSurah: session.surah != null,
    hasTimedReciter: session.moshaf?.hasTiming ?? false,
    isEnded: view.isEnded,
    isInitializing: view.isInitializing,
    isLoading: view.isLoading,
    isPlaying: view.isPlaying,
    reciterName: session.reciter?.name,
  );
}

String recitationTransportPlaybackLabel({
  required AppLocalizations l10n,
  required RecitationTransportPlaybackState state,
  String? surahName,
}) {
  final action = state.isEnded
      ? l10n.globalPlaybackReplay
      : state.isPlaying
      ? l10n.quranRecitationPause
      : l10n.quranRecitationPlay;
  final context = <String>[
    if ((surahName ?? '').trim().isNotEmpty) surahName!.trim(),
    if ((state.reciterName ?? '').trim().isNotEmpty) state.reciterName!.trim(),
  ];
  final missingContext = switch (()) {
    _ when !state.hasReciter => l10n.globalPlaybackChooseReciter,
    _ when !state.hasMoshaf => l10n.globalPlaybackChooseMoshaf,
    _ when !state.hasSurah => l10n.globalPlaybackChooseSurah,
    _ when state.hasRangeSelection && !state.hasTimedReciter =>
      l10n.quranRangeRequiresTimedReciter,
    _ => l10n.quranRecitationUnavailable,
  };

  return <String>[
    action,
    if (state.isInitializing || state.isLoading) l10n.loading,
    if (state.hasInitializationError) l10n.quranRecitationInitializationFailed,
    if (!state.canPlay &&
        !state.isInitializing &&
        !state.isLoading &&
        !state.hasInitializationError)
      missingContext,
    ...context,
  ].join(' · ');
}

/// Compact inline transport that lives in the title bar.
///
/// Always visible so the user can open the player or resume from any screen.
class RecitationTransport extends ConsumerWidget {
  /// Creates a [RecitationTransport].
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _TransportPill();
  }
}

class _TransportPill extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;

    // Chrome only — avoid rebuilding the title-bar pill on every position tick.
    final chrome = ref.watch(
      recitationViewProvider.select(
        (view) => (
          active: view.session.active,
          surah: view.session.surah,
          currentAyah: view.session.currentAyah,
          playback: recitationTransportPlaybackState(view),
        ),
      ),
    );
    final drawerOpen = ref.watch(recitationDrawerProvider);
    final controller = ref.read(recitationControllerProvider.notifier);
    final mushaf = ref.read(quranMushafControllerProvider);
    final hasAyahTiming = controller.hasAyahTiming;

    final playback = chrome.playback;
    final isLoading = playback.isLoading;
    final isEnded = playback.isEnded;
    final surah = chrome.surah;
    final isInitializing = playback.isInitializing;
    final surahName = AyahReferenceLogic.surahName(
      isInitializing || surah == null ? null : mushaf.getSurahSync(surah),
      surah ?? 0,
      preferArabic: Localizations.localeOf(context).languageCode == 'ar',
      fallbackName: '',
    );

    final titleStyle = theme.typography.body.sm.copyWith(
      color: colors.foreground,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );
    final titleWidget = isInitializing
        ? FSkeletonizer(
            child: SizedBox(width: 72, child: Text('Surah', style: titleStyle)),
          )
        : surahName.isEmpty
        ? const SizedBox.shrink()
        : chrome.currentAyah != null
        ? SurahNameWithSuffix(
            surahName: surahName,
            suffix: ' · ${chrome.currentAyah}',
            style: titleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        : SurahNameText(
            surahName,
            style: titleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );

    final playbackLabel = recitationTransportPlaybackLabel(
      l10n: l10n,
      state: chrome.playback,
      surahName: surahName,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
        final showSkip =
            chrome.active &&
            surah != null &&
            !isInitializing &&
            playback.canPlay;
        final isRtl = Directionality.of(context) == TextDirection.rtl;

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: IntrinsicWidth(
            child: FTile(
              style: _compactTileStyle(theme),
              semanticsLabel: drawerOpen
                  ? l10n.quranRecitationClosePlayer
                  : l10n.quranRecitationOpenPlayer,
              prefix: RecitationTransportControls(
                isPlaying: playback.isPlaying,
                isLoading: isLoading,
                isInitializing: isInitializing,
                canPlay: playback.canPlay,
                isEnded: isEnded,
                onPlayPause: playback.canPlay
                    ? controller.togglePlayPause
                    : null,
                leftSlot: leftSkipControl(
                  isRtl: isRtl,
                  skipPrevious: hasAyahTiming
                      ? controller.skipAyahPrevious
                      : controller.skipSurahPrevious,
                  skipNext: hasAyahTiming
                      ? controller.skipAyahNext
                      : controller.skipSurahNext,
                  previousLabel: hasAyahTiming
                      ? l10n.quranRecitationPreviousAyah
                      : l10n.quranRecitationPreviousSurah,
                  nextLabel: hasAyahTiming
                      ? l10n.quranRecitationNextAyah
                      : l10n.quranRecitationNextSurah,
                  icon: hasAyahTiming
                      ? FLucideIcons.arrowLeft
                      : FLucideIcons.skipBack,
                ),
                rightSlot: rightSkipControl(
                  isRtl: isRtl,
                  skipPrevious: hasAyahTiming
                      ? controller.skipAyahPrevious
                      : controller.skipSurahPrevious,
                  skipNext: hasAyahTiming
                      ? controller.skipAyahNext
                      : controller.skipSurahNext,
                  previousLabel: hasAyahTiming
                      ? l10n.quranRecitationPreviousAyah
                      : l10n.quranRecitationPreviousSurah,
                  nextLabel: hasAyahTiming
                      ? l10n.quranRecitationNextAyah
                      : l10n.quranRecitationNextSurah,
                  icon: hasAyahTiming
                      ? FLucideIcons.arrowRight
                      : FLucideIcons.skipForward,
                ),
                showSkip: showSkip,
                playbackSemanticsLabel: playbackLabel,
                playbackTooltip: playbackLabel,
              ),
              title: isInitializing || surahName.isNotEmpty
                  ? Row(
                      children: [
                        Container(
                          width: 1,
                          height: 24,
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: colors.border,
                            borderRadius: theme.radii.sm,
                          ),
                        ),
                        titleWidget,
                      ],
                    )
                  : const SizedBox.shrink(),
              suffix: _TransportSuffix(
                isPlaying: playback.isPlaying,
                isEnded: isEnded,
                drawerOpen: drawerOpen,
              ),
              onPress: ref.read(recitationDrawerProvider.notifier).toggle,
            ),
          ),
        );
      },
    );
  }
}

/// Chevron and equalizer shown at the end of the transport pill.
class _TransportSuffix extends StatelessWidget {
  const new({
    required this.isPlaying,
    required this.isEnded,
    required this.drawerOpen,
  });

  final bool isPlaying;
  final bool isEnded;
  final bool drawerOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isPlaying && !isEnded) ...[
          RecitationEqualizer(color: colors.primary, animating: !drawerOpen),
          const SizedBox(width: AppSpacing.sm),
        ],
        Icon(
          drawerOpen ? FLucideIcons.chevronUp : FLucideIcons.chevronDown,
          size: 17,
          color: colors.mutedForeground,
        ),
      ],
    );
  }
}

/// A compact [FTileStyle] suitable for the constrained title bar pill.
FTileStyle _compactTileStyle(FThemeData theme) {
  final base = theme.tileStyles.primary;
  return base.copyWith(
    contentDecoration: .delta([
      .all(.boxDelta(border: .all(color: Colors.transparent))),
    ]),
    contentStyle: base.contentStyle.copyWith(
      suffixedPadding: const EdgeInsetsGeometryDelta.value(
        EdgeInsets.fromLTRB(6, 4, 8, 4),
      ),
      unsuffixedPadding: const EdgeInsetsGeometryDelta.value(
        EdgeInsets.fromLTRB(6, 4, 8, 4),
      ),
      prefixIconSpacing: 6,
      suffixIconSpacing: 4,
    ),
  );
}
