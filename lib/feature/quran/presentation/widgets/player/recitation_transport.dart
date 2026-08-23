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
import 'package:tawaq/theme/theme.dart';

export 'package:tawaq/feature/quran/presentation/widgets/player/recitation_transport_controls.dart'
    show SkipAction, SkipControl, leftSkipControl, rightSkipControl;

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
          isInitializing: view.isInitializing,
          canPlay: view.canPlay,
          isLoading: view.isLoading,
          isEnded: view.isEnded,
          isPlaying: view.isPlaying,
        ),
      ),
    );
    final drawerOpen = ref.watch(recitationDrawerProvider);
    final controller = ref.read(recitationControllerProvider.notifier);
    final mushaf = ref.read(quranMushafControllerProvider);
    final hasAyahTiming = controller.hasAyahTiming;

    final isLoading = chrome.isLoading;
    final isEnded = chrome.isEnded;
    final surah = chrome.surah;
    final isInitializing = chrome.isInitializing;
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
        final showSkip =
            chrome.active && surah != null && !isInitializing && chrome.canPlay;
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
                isPlaying: chrome.isPlaying,
                isLoading: isLoading,
                isInitializing: isInitializing,
                canPlay: chrome.canPlay,
                isEnded: isEnded,
                onPlayPause: chrome.canPlay ? controller.togglePlayPause : null,
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
                isPlaying: chrome.isPlaying,
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
