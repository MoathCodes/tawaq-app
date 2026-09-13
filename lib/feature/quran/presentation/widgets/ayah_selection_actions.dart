import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/presentation/extensions/ayah_reference_formatter.dart';
import 'package:tawaq/feature/quran/presentation/hooks/quran_ayah_selection.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/range_repeat_dialog.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/reciter_dialog.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/share/ayah_share_dialog.dart';
import 'package:tawaq/theme/theme.dart';

const _actionButtonShortcuts = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
};

/// Animated contextual actions attached to the bottom of the Quran reader.
class AyahSelectionActionsBar extends ConsumerWidget {
  /// Creates the selection actions bar.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final durations = theme.durations;
    final selectedAyah = ref.watch(quranSelectedAyahProvider).value;

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
  const new({required this.ayah, super.key});

  final Ayah ayah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final durations = theme.durations;
    final l10n = context.l10n;
    final colors = theme.colors;
    final controller = ref.watch(quranMushafControllerProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final reference = localizedAyahReference(
      ayah: ayah,
      controller: controller,
      l10n: l10n,
      isArabic: isArabic,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // The reader can offer a narrower toolbar than the app breakpoint.
        // Base this choice on the space actually available to this group so a
        // desktop reader still exposes the text actions and play chevron.
        final compact = constraints.maxWidth < 420;

        Widget playTrigger(VoidCallback toggle) => compact
            ? _iconAction(
                label: l10n.quranRecitationPlay,
                icon: FLucideIcons.play,
                onPress: toggle,
                variant: FButtonVariant.primary,
              )
            : _labeledAction(
                label: l10n.quranRecitationPlay,
                onPress: toggle,
                variant: FButtonVariant.primary,
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
            ? _iconAction(
                label: l10n.ayahShare,
                icon: FLucideIcons.share2,
                onPress: () => showAyahShareDialog(context, ayah: ayah),
                variant: FButtonVariant.outline,
              )
            : _labeledAction(
                label: l10n.ayahShare,
                onPress: () => showAyahShareDialog(context, ayah: ayah),
                variant: FButtonVariant.outline,
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
            ? _iconAction(
                label: l10n.ayahCopy,
                icon: FLucideIcons.copy,
                onPress: () => copySelectedAyah(context, ref, ayah),
                variant: FButtonVariant.outline,
              )
            : _labeledAction(
                label: l10n.ayahCopy,
                onPress: () => copySelectedAyah(context, ref, ayah),
                variant: FButtonVariant.outline,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.ayahCopy),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(FLucideIcons.copy, size: 18),
                  ],
                ),
              );

        final dismissButton = _iconAction(
          label: l10n.quranStudyDismissSelection,
          icon: FLucideIcons.x,
          onPress: () => setQuranSelectedAyah(ref, null),
          variant: FButtonVariant.ghost,
        );

        final actionControls = Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
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
            dismissButton,
          ],
        );

        final width = constraints.maxWidth.clamp(0.0, 520.0);
        final surface = SizedBox(
          key: const ValueKey('ayah-selection-actions-surface'),
          width: width,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.background,
              border: Border.all(color: colors.border),
              borderRadius: theme.radii.lg,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    reference,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  actionControls,
                ],
              ),
            ),
          ),
        );
        return Align(
          alignment: AlignmentDirectional.center,
          child: surface
              .animate()
              .fadeIn(duration: durations.fast, curve: Curves.easeOut)
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1, 1),
                duration: durations.normal,
                curve: Curves.easeOutBack,
              ),
        );
      },
    );
  }

  Widget _iconAction({
    required String label,
    required IconData icon,
    required VoidCallback onPress,
    required FButtonVariant variant,
  }) {
    final button = FButton.icon(
      variant: variant,
      onPress: onPress,
      shortcuts: _actionButtonShortcuts,
      child: Icon(icon, size: 18),
    );
    return FTooltip(
      tipBuilder: (_, _) => Text(label, semanticsLabel: label),
      child: QuranSemantics.labeledControl(
        name: label,
        onTap: onPress,
        button: true,
        excludeChild: true,
        child: button,
      ),
    );
  }

  Widget _labeledAction({
    required String label,
    required VoidCallback onPress,
    required FButtonVariant variant,
    required Widget child,
  }) {
    return QuranSemantics.labeledControl(
      name: label,
      onTap: onPress,
      button: true,
      excludeChild: true,
      child: FButton(
        variant: variant,
        onPress: onPress,
        shortcuts: _actionButtonShortcuts,
        mainAxisSize: MainAxisSize.min,
        child: child,
      ),
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
    var selected = ref.read(selectedRecitationProvider).value;
    if (selected == null) {
      await showReciterDialog(context, intent: intent);
      if (!context.mounted) return null;
      selected = ref.read(selectedRecitationProvider).value;
    }
    if (selected == null) return null;
    return (reciter: selected.reciter, moshaf: selected.moshaf);
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
    await ref
        .read(recitationControllerProvider.notifier)
        .playSurah(
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
  showFToast(context: context, title: Text(l10n.ayahCopied(reference)));
}
