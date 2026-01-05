import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/feature/quran/presentation/providers/audio_player_provider.dart';
import 'package:hasanat/theme/theme.dart';

/// A compact footer audio player bar for Quran recitation.
///
/// Designed to take minimal vertical space while providing essential controls.
class AudioPlayerBar extends ConsumerWidget {
  /// Creates an audio player bar.
  const AudioPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(audioPlayerProvider);
    final notifier = ref.read(audioPlayerProvider.notifier);
    final colors = FTheme.of(context).colors;
    final typography = FTheme.of(context).typography;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border, width: 0.5)),
      ),
      padding: const .symmetric(horizontal: 12, vertical: 6),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Play/Pause button
            _PlayButton(
              isPlaying: state.isPlaying,
              onPressed: notifier.togglePlayPause,
              colors: colors,
            ),
            const SizedBox(width: AppSpacing.sm),
            // Surah & ayah info
            Expanded(
              child: _TrackInfo(
                surahName: state.surahName,
                ayahNumber: state.currentAyahNumber,
                reciterName: state.reciterName,
                typography: typography,
                colors: colors,
              ),
            ),
            // Navigation controls
            _NavigationControls(
              onPrevious: notifier.previousAyah,
              onNext: notifier.nextAyah,
              colors: colors,
            ),
            const SizedBox(width: AppSpacing.xs),
            // Close button
            _CloseButton(
              onPressed: notifier.hidePlayer,
              colors: colors,
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 1, end: 0);
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.onPressed,
    required this.colors,
  });

  final bool isPlaying;
  final VoidCallback onPressed;
  final FColors colors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? FIcons.pause : FIcons.play,
          size: 18,
          color: colors.primaryForeground,
        ),
      ),
    );
  }
}

class _TrackInfo extends StatelessWidget {
  const _TrackInfo({
    required this.surahName,
    required this.ayahNumber,
    required this.reciterName,
    required this.typography,
    required this.colors,
  });

  final String surahName;
  final int ayahNumber;
  final String reciterName;
  final FTypography typography;
  final FColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: .start,
      children: [
        Text(
          '$surahName • Ayah $ayahNumber',
          style: typography.sm.copyWith(
            fontWeight: FontWeight.w500,
            color: colors.foreground,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          reciterName,
          style: typography.xs.copyWith(color: colors.mutedForeground),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _NavigationControls extends StatelessWidget {
  const _NavigationControls({
    required this.onPrevious,
    required this.onNext,
    required this.colors,
  });

  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final FColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPrevious,
          child: Padding(
            padding: const .all(AppSpacing.sm),
            child: Icon(FIcons.skipBack, size: 20, color: colors.foreground),
          ),
        ),
        GestureDetector(
          onTap: onNext,
          child: Padding(
            padding: const .all(AppSpacing.sm),
            child: Icon(FIcons.skipForward, size: 20, color: colors.foreground),
          ),
        ),
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({
    required this.onPressed,
    required this.colors,
  });

  final VoidCallback onPressed;
  final FColors colors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Padding(
        padding: const .all(AppSpacing.sm),
        child: Icon(FIcons.x, size: 18, color: colors.mutedForeground),
      ),
    );
  }
}
