import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_equalizer.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_transport_controls.dart';
import 'package:tawaq/feature/quran/presentation/widgets/surah_name_text.dart';
import 'package:tawaq/theme/theme.dart';

export 'package:tawaq/feature/quran/presentation/widgets/player/recitation_transport_controls.dart'
    show SkipAction, SkipControl, leftSkipControl, rightSkipControl;

/// Compact inline transport that lives in the title bar.
///
/// Always visible so the user can open the player or resume from any screen.
class RecitationTransport extends ConsumerWidget {
  /// Creates a [RecitationTransport].
  const RecitationTransport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _TransportPill();
  }
}

class _TransportPill extends HookConsumerWidget {
  const _TransportPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;

    // Chrome only — avoid rebuilding the title-bar pill on every position tick.
    final chrome = ref.watch(
      recitationControllerProvider.select(
        (p) => (
          status: p.status,
          active: p.active,
          surah: p.surah,
          currentAyah: p.currentAyah,
        ),
      ),
    );
    final drawerOpen = ref.watch(recitationDrawerProvider);
    final controller = ref.read(recitationControllerProvider.notifier);
    final mushaf = ref.read(quranMushafControllerProvider);
    final hasAyahTiming = controller.hasAyahTiming;

    final isLoading = chrome.status == RecitationStatus.loading;
    final isEnded = chrome.status == RecitationStatus.ended;
    final showMetadata = chrome.active;

    final audioService = ref.watch(tawaqAudioServiceProvider);
    final playWhenReady =
        useStream(
          useMemoized(
            () => audioService.playWhenReadyStream,
            [audioService],
          ),
        ).data ??
        audioService.playWhenReady;

    final surah = chrome.surah;
    final surahName = surah == null
        ? ''
        : mushaf.getSurahSync(surah)?.displayName ??
              l10n.quranSurahLabel('$surah');

    final titleStyle = theme.typography.body.sm.copyWith(
      color: colors.foreground,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );
    final titleWidget = chrome.currentAyah != null
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
        final showSkip = chrome.active && surah != null;
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
                isPlaying: playWhenReady,
                isLoading: isLoading,
                isEnded: isEnded,
                onPlayPause: controller.togglePlayPause,
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
              ),
              title: showMetadata || surahName.isNotEmpty
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
                isPlaying: playWhenReady,
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
  const _TransportSuffix({
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
          RecitationEqualizer(
            color: colors.primary,
            animating: !drawerOpen,
          ),
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
