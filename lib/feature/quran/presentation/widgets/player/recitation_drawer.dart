import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/format_byte_size.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/core/widgets/volume_slider.dart';
import 'package:tawaq/feature/quran/data/sources/recitation_cache.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_timeline.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_data_providers.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/offline_files_dialog.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/range_repeat_dialog.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/reciter_dialog.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/sleep_timer_dialog.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_seek_bar.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_transport_controls.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/ayah_range_formatters.dart';
import 'package:tawaq/feature/quran/presentation/widgets/surah_name_text.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

part 'recitation_drawer_controls.dart';

/// The full recitation transport that drops down under the title bar when the
/// user expands the compact transport. Rendered as an overlay (scrim + panel)
/// so it floats above the routed content on any screen.
class RecitationDrawerOverlay extends ConsumerWidget {
  /// Creates a [RecitationDrawerOverlay].
  const RecitationDrawerOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(recitationDrawerProvider);
    return RecitationDrawerSurface(
      open: open,
      onClose: ref.read(recitationDrawerProvider.notifier).close,
      child: const _DrawerPanel(),
    );
  }
}

/// The animated surface wrapper around the drawer panel, exposed for testing.
@visibleForTesting
class RecitationDrawerSurface extends StatefulWidget {
  /// Creates a [RecitationDrawerSurface].
  const RecitationDrawerSurface({
    required this.open,
    required this.onClose,
    required this.child,
    this.duration = const Duration(milliseconds: 220),
    super.key,
  });

  final bool open;
  final VoidCallback onClose;
  final Widget child;
  final Duration duration;

  @override
  State<RecitationDrawerSurface> createState() =>
      RecitationDrawerSurfaceState();
}

/// Public state for [RecitationDrawerSurface], exposing the animation
/// [controller] so widget tests can assert the open/close animation runs in
/// both directions.
class RecitationDrawerSurfaceState extends State<RecitationDrawerSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.open ? 1 : 0,
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void didUpdateWidget(covariant RecitationDrawerSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open != widget.open) {
      if (widget.open) {
        unawaited(_controller.forward());
      } else {
        unawaited(_controller.reverse());
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  AnimationController get controller => _controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_controller.isCompleted,
                child: MouseClick(
                  onClick: widget.onClose,
                  child: ColoredBox(
                    color: colors.barrier
                        .withValues(alpha: 0.45 * _fade.value),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: FadeTransition(
                opacity: _fade,
                child: AnimatedSize(
                  duration: widget.duration,
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: _controller.value > 0
                      ? widget.child
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DrawerPanel extends HookConsumerWidget {
  const _DrawerPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final playback = ref.watch(recitationControllerProvider);
    final controller = ref.read(recitationControllerProvider.notifier);
    final leftSlot = leftSkipControl(
      isRtl: isRtl,
      skipPrevious: controller.skipPrevious,
      skipNext: controller.skipNext,
      previousLabel: l10n.quranRecitationPrevious,
      nextLabel: l10n.quranRecitationNext,
    );
    final rightSlot = rightSkipControl(
      isRtl: isRtl,
      skipPrevious: controller.skipPrevious,
      skipNext: controller.skipNext,
      previousLabel: l10n.quranRecitationPrevious,
      nextLabel: l10n.quranRecitationNext,
    );
    final settings = ref.watch(recitationSettingsProvider).value;
    final mushaf = ref.read(quranMushafControllerProvider);

    final surah = playback.surah;
    final surahName = surah == null
        ? ''
        : mushaf.getSurahSync(surah)?.displayName ??
              l10n.quranSurahLabel('$surah');
    final reciterName = playback.reciter?.name ?? '';
    final riwayah = playback.moshaf?.name ?? '';

    final rangeLabel = playback.rangeFrom != null
        ? formatAyahRangeLabel(
            mushaf: mushaf,
            l10n: l10n,
            from: playback.rangeFrom!,
            to: playback.rangeTo,
          )
        : surahName;
    final subtitleStyle = theme.typography.body.xs.copyWith(
      color: colors.mutedForeground,
    );
    final rangeWidget = rangeLabel.isEmpty
        ? null
        : AyahRangeLabelText(
            rangeLabel,
            style: subtitleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
    final showSubtitle = riwayah.isNotEmpty || rangeWidget != null;

    final ayahRepeat = settings?.ayahRepeatCount ?? 1;
    final rangeRepeat = settings?.rangeRepeatCount ?? 1;
    final repeatSuffix = () {
      if (ayahRepeat <= 1 && rangeRepeat <= 1) return '';
      final parts = <String>[];
      if (ayahRepeat > 1) {
        parts.add(
          '${l10n.quranRangeRepeatChip(ayahRepeat)} ${l10n.quranRangeRepeatEachAyah}',
        );
      }
      if (rangeRepeat > 1) {
        parts.add(
          '${l10n.quranRangeRepeatChip(rangeRepeat)} ${l10n.quranRangeRepeatSelection}',
        );
      }
      return ' · ${parts.join(' · ')}';
    }();
    final persistedVolume = settings?.volume ?? 100;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(320.0, 680.0)
            : 620.0;
        final isNarrow = width < 480;

        return Container(
          width: width,
          margin: const EdgeInsets.only(bottom: AppSpacing.xl),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.card,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.vertical(
              bottom: context.theme.radii.xl.bottomLeft,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.barrier.withValues(alpha: 0.4),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DrawerHeader(
                reciterName: reciterName,
                riwayah: riwayah,
                rangeWidget: rangeWidget,
                showSubtitle: showSubtitle,
              ),
              const SizedBox(height: AppSpacing.lg),
              _DrawerTransportSection(
                leftSlot: leftSlot,
                rightSlot: rightSlot,
              ),
              const SizedBox(height: AppSpacing.lg),
              _DrawerActionsSection(
                rangeLabel: rangeLabel,
                rangeWidget: rangeWidget,
                surahName: surahName,
                repeatSuffix: repeatSuffix,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(height: 1, color: colors.border),
              const SizedBox(height: AppSpacing.md),
              _DrawerSettingsSection(
                isNarrow: isNarrow,
                persistedVolume: persistedVolume,
              ),
            ],
          ),
        );
      },
    );
  }
}
