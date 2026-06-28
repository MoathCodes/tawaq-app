import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_pick_intent.dart';
import 'package:tawaq/feature/quran/presentation/extensions/ayah_reference_formatter.dart';
import 'package:tawaq/feature/quran/presentation/hooks/quran_ayah_selection.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/range_repeat_dialog.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/reciter_dialog.dart';
import 'package:tawaq/feature/quran/presentation/widgets/share/ayah_share_dialog.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Animated floating bar for copy, share, and play on the selected ayah.
class AyahSelectionActionsBar extends ConsumerWidget {
  /// Creates the selection actions bar.
  const AyahSelectionActionsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final durations = theme.durations;
    final selectedAyah = ref.watch(
      quranScreenSettingsProvider.select((v) => v.value?.selectedAyah),
    );

    return AnimatedSwitcher(
      duration: durations.normal,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide =
            Tween<Offset>(
              begin: const Offset(0, 0.35),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: selectedAyah == null
          ? const SizedBox.shrink(key: ValueKey('ayah-actions-hidden'))
          : _AyahSelectionActionsContent(
              key: ValueKey(selectedAyah.ayahId),
              ayah: selectedAyah,
            ),
    );
  }
}

class _AyahSelectionActionsContent extends ConsumerWidget {
  const _AyahSelectionActionsContent({
    required this.ayah,
    super.key,
  });

  final Ayah ayah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final durations = theme.durations;
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < theme.breakpoints.sm;

        Widget playTrigger(VoidCallback toggle) => compact
            ? FButton.icon(
                onPress: toggle,
                child: const Icon(FLucideIcons.play, size: 18),
              )
            : FButton(
                onPress: toggle,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.quranRecitationPlay),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(FLucideIcons.chevronDown, size: 18),
                  ],
                ),
              );

        final shareButton = compact
            ? FButton.icon(
                onPress: () => showAyahShareDialog(context, ayah: ayah),
                child: const Icon(FLucideIcons.share2, size: 18),
              )
            : FButton(
                onPress: () => showAyahShareDialog(context, ayah: ayah),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.ayahShare),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(FLucideIcons.share2, size: 18),
                  ],
                ),
              );

        final copyButton = compact
            ? FButton.icon(
                onPress: () => copySelectedAyah(context, ref, ayah),
                child: const Icon(FLucideIcons.copy, size: 18),
              )
            : FButton.icon(
                onPress: () => copySelectedAyah(context, ref, ayah),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.ayahCopy),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(FLucideIcons.copy, size: 18),
                  ],
                ),
              );

        return Row(
          spacing: AppSpacing.sm,
          mainAxisSize: MainAxisSize.min,
          children: [
            FPopoverMenu(
              menu: [
                FItemGroup(
                  children: [
                    FItem(
                      prefix: const Icon(FLucideIcons.play),
                      title: Text(l10n.quranPlayAyah),
                      onPress: () =>
                          unawaited(_playAyahAction(context, ref, ayah)),
                    ),
                    FItem(
                      prefix: const Icon(FLucideIcons.bookOpen),
                      title: Text(l10n.quranPlaySurah),
                      onPress: () =>
                          unawaited(_playSurahAction(context, ref, ayah)),
                    ),
                    FItem(
                      prefix: const Icon(FLucideIcons.repeat),
                      title: Text(l10n.quranPlayRange),
                      onPress: () =>
                          unawaited(_playRangeAction(context, ref, ayah)),
                    ),
                  ],
                ),
              ],
              builder: (context, controller, _) =>
                  playTrigger(controller.toggle),
            ),
            shareButton,
            copyButton,
            FButton.icon(
              onPress: () => setQuranSelectedAyah(ref, null),
              child: const Icon(FLucideIcons.x, size: 18),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: durations.fast, curve: Curves.easeOut)
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1, 1),
              duration: durations.normal,
              curve: Curves.easeOutBack,
            );
      },
    );
  }

  void _showRecitationUnavailableToast(BuildContext context) {
    showFToast(
      context: context,
      variant: .destructive,
      icon: const Icon(FLucideIcons.triangleAlert),
      title: Text(context.l10n.quranRecitationUnavailable),
    );
  }

  void _showNoTimingToast(BuildContext context) {
    showFToast(
      context: context,
      variant: .destructive,
      icon: const Icon(FLucideIcons.triangleAlert),
      title: Text(context.l10n.quranRecitationNoTiming),
    );
  }

  Future<ReciterPick?> _ensureCurrentPick(
    BuildContext context,
    WidgetRef ref, {
    RecitationPickIntent intent = RecitationPickIntent.ayahLevel,
  }) async {
    var reciter = ref.read(selectedReciterProvider).value;
    var settings = ref.read(recitationSettingsProvider).value;
    if (reciter == null) {
      await showReciterDialog(context, intent: intent);
      if (!context.mounted) return null;
      reciter = ref.read(selectedReciterProvider).value;
      settings = ref.read(recitationSettingsProvider).value;
    }
    if (reciter == null) return null;
    final moshaf = reciter.resolveMoshaf(settings?.moshafId);
    if (moshaf == null) return null;
    return (reciter: reciter, moshaf: moshaf);
  }

  Future<void> _playAyahAction(
    BuildContext context,
    WidgetRef ref,
    Ayah ayah,
  ) async {
    final pick = await _ensureCurrentPick(context, ref);
    if (pick == null || !context.mounted) return;
    if (!pick.moshaf.hasTiming) {
      _showNoTimingToast(context);
      return;
    }
    final started = await ref
        .read(recitationControllerProvider.notifier)
        .playRange(
          reciter: pick.reciter,
          moshaf: pick.moshaf,
          surah: ayah.surahNumber,
          startAyah: ayah.numberInSurah,
          endAyah: ayah.numberInSurah,
        );
    if (!started && context.mounted) {
      _showNoTimingToast(context);
    }
  }

  Future<void> _playSurahAction(
    BuildContext context,
    WidgetRef ref,
    Ayah ayah,
  ) async {
    final pick = await _ensureCurrentPick(
      context,
      ref,
      intent: RecitationPickIntent.general,
    );
    if (pick == null || !context.mounted) return;
    if (!pick.moshaf.hasSurah(ayah.surahNumber)) {
      if (context.mounted) _showRecitationUnavailableToast(context);
      return;
    }
    await ref.read(recitationControllerProvider.notifier).playSurah(
      reciter: pick.reciter,
      moshaf: pick.moshaf,
      surah: ayah.surahNumber,
    );
  }

  Future<void> _playRangeAction(
    BuildContext context,
    WidgetRef ref,
    Ayah ayah,
  ) async {
    final pick = await _ensureCurrentPick(context, ref);
    if (pick == null || !context.mounted) return;
    await showRangeRepeatDialog(
      context,
      initial: RangeRepeatInit(
        reciter: pick.reciter,
        moshaf: pick.moshaf,
        surah: ayah.surahNumber,
        startAyah: ayah.numberInSurah,
      ),
    );
  }
}

/// Copies the selected ayah text and reference to the clipboard.
void copySelectedAyah(BuildContext context, WidgetRef ref, Ayah ayah) {
  final controller = ref.read(quranMushafControllerProvider);
  final l10n = context.l10n;
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final reference = localizedAyahReference(
    ayah: ayah,
    controller: controller,
    l10n: l10n,
    isArabic: isArabic,
  );
  final text = ayah.textPlain?.trim();
  unawaited(
    Clipboard.setData(
      ClipboardData(
        text: text != null && text.isNotEmpty
            ? '$text\n— $reference'
            : reference,
      ),
    ),
  );
  showFToast(
    context: context,
    title: Text(l10n.ayahCopied(reference)),
  );
}
