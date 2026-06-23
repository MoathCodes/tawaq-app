import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/audio/playback_state.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_equalizer.dart';
import 'package:tawaq/feature/quran/presentation/widgets/surah_name_text.dart';
import 'package:tawaq/theme/theme.dart';

/// Minimum allocated width before the reciter subtitle is shown.
const _kTransportSubtitleMinWidth = 300.0;

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

class _TransportPill extends ConsumerWidget {
  const _TransportPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;

    final playbackState = ref.watch(audioPlayerControllerProvider);
    final drawerOpen = ref.watch(recitationDrawerProvider);

    final isPlaying = playbackState is PlaybackPlaying;
    final isLoading = playbackState is PlaybackLoading;

    final surah = ref.watch(
      recitationControllerProvider.select((playback) => playback.surah),
    );
    final currentAyah = ref.watch(
      recitationControllerProvider.select((playback) => playback.currentAyah),
    );
    final playbackReciter = ref.watch(
      recitationControllerProvider.select((playback) => playback.reciter),
    );
    final controller = ref.read(recitationControllerProvider.notifier);
    final mushaf = ref.read(quranMushafControllerProvider);
    final surahName = surah == null
        ? ''
        : mushaf.getSurahSync(surah)?.displayName ??
              l10n.quranSurahLabel('$surah');
    final selectedReciter = ref.watch(selectedReciterProvider).value;
    final titleStyle = theme.typography.body.sm.copyWith(
      color: colors.foreground,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );
    final titleWidget = currentAyah != null
        ? SurahNameWithSuffix(
            surahName: surahName,
            suffix: ' · $currentAyah',
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
    final reciterName =
        playbackReciter?.name ?? selectedReciter?.name ?? '';
    final isIdle = surah == null && playbackState is PlaybackIdle;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
        final showSubtitle =
            reciterName.isNotEmpty &&
            maxWidth >= _kTransportSubtitleMinWidth &&
            !isIdle;

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            padding: const EdgeInsets.fromLTRB(6, 5, 8, 5),
            decoration: BoxDecoration(
              color: colors.secondary,
              border: Border.all(color: colors.border),
              borderRadius: context.theme.radii.lg,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RoundPlayButton(
                  isPlaying: isPlaying,
                  isLoading: isLoading,
                  onPressed: controller.togglePlayPause,
                ),
                if (!isIdle) ...[
                  const SizedBox(width: AppSpacing.md),
                  Flexible(
                    child: FTappable(
                      semanticsLabel: drawerOpen
                          ? l10n.quranRecitationClosePlayer
                          : l10n.quranRecitationOpenPlayer,
                      onPress:
                          ref.read(recitationDrawerProvider.notifier).toggle,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                titleWidget,
                                if (showSubtitle)
                                  Text(
                                    reciterName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.typography.body.xs.copyWith(
                                      color: colors.mutedForeground,
                                      height: 1.2,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isPlaying) ...[
                            const SizedBox(width: AppSpacing.md),
                            RecitationEqualizer(
                              color: colors.primary,
                              animating: !drawerOpen,
                            ),
                          ],
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            width: 1,
                            height: 24,
                            color: colors.border,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            drawerOpen
                                ? FLucideIcons.chevronUp
                                : FLucideIcons.chevronDown,
                            size: 17,
                            color: colors.mutedForeground,
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: AppSpacing.sm),
                  FTappable(
                    semanticsLabel: drawerOpen
                        ? l10n.quranRecitationClosePlayer
                        : l10n.quranRecitationOpenPlayer,
                    onPress: ref.read(recitationDrawerProvider.notifier).toggle,
                    child: Icon(
                      drawerOpen
                          ? FLucideIcons.chevronUp
                          : FLucideIcons.chevronDown,
                      size: 17,
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RoundPlayButton extends StatelessWidget {
  const _RoundPlayButton({
    required this.isPlaying,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isPlaying;
  final bool isLoading;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    if (isLoading) {
      return const SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: FCircularProgress(size: FCircularProgressSizeVariant.sm),
        ),
      );
    }
    return FTappable(
      onPress: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.primary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          isPlaying ? FLucideIcons.pause : FLucideIcons.play,
          size: 18,
          color: colors.primaryForeground,
        ),
      ),
    );
  }
}
