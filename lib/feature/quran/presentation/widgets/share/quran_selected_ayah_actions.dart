import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/domain/models/quran_layouts.dart';
import 'package:tawaq/feature/quran/presentation/extensions/ayah_reference_formatter.dart';
import 'package:tawaq/feature/quran/presentation/hooks/quran_ayah_selection.dart';
import 'package:tawaq/feature/quran/presentation/widgets/share/ayah_share_dialog.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Wraps the mushaf reader and overlays a floating actions bar when an
/// ayah is selected.
class QuranReaderWithAyahActions extends StatelessWidget {
  /// Creates a reader shell with selection actions.
  const QuranReaderWithAyahActions({
    required this.reader,
    required this.controller,
    required this.layout,
    super.key,
  });

  /// The mushaf reader widget.
  final Widget reader;

  /// Controller used to clear mushaf highlight when dismissing the bar.
  final MushafReaderController controller;

  /// Active reading layout (controls action bar placement).
  final QuranReadingLayout layout;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        reader,
        Positioned(
          left: 0,
          right: 0,
          bottom: AppSpacing.lg,
          child: Align(
            alignment: _ayahActionsAlignment(context, layout),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: layout == QuranReadingLayout.studyMode
                    ? AppSpacing.lg
                    : 0,
              ),
              child: QuranSelectedAyahActionsBar(controller: controller),
            ),
          ),
        ),
      ],
    );
  }
}

/// Study mode pins the bar to the mushaf pane's outer edge (away from the
/// study panel). Double-page mode keeps it centered over the spread.
Alignment _ayahActionsAlignment(
  BuildContext context,
  QuranReadingLayout layout,
) {
  if (layout != QuranReadingLayout.studyMode) {
    return Alignment.bottomCenter;
  }

  // Study chrome uses LTR layout; locale decides which pane holds the mushaf.
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  return isArabic ? Alignment.bottomLeft : Alignment.bottomRight;
}

/// Animated floating bar for copy, share, and bookmark on the selected ayah.
class QuranSelectedAyahActionsBar extends ConsumerWidget {
  /// Creates the selection actions bar.
  const QuranSelectedAyahActionsBar({required this.controller, super.key});

  final MushafReaderController controller;

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
          : _AyahActionsBar(
              key: ValueKey(selectedAyah.ayahId),
              controller: controller,
              ayah: selectedAyah,
              onClose: () => setQuranSelectedAyah(ref, controller, null),
            ),
    );
  }
}

class _AyahActionsBar extends StatelessWidget {
  const _AyahActionsBar({
    required this.controller,
    required this.ayah,
    required this.onClose,
    super.key,
  });

  final MushafReaderController controller;
  final Ayah ayah;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final durations = theme.durations;
    final l10n = context.l10n;

    return Row(
          spacing: AppSpacing.sm,
          mainAxisSize: MainAxisSize.min,
          children: [
            FButton(
              onPress: () => showAyahShareDialog(
                context,
                controller: controller,
                ayah: ayah,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.ayahShare),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(FLucideIcons.share2, size: 18),
                ],
              ),
            ),
            FButton.icon(
              onPress: () {},
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.ayahBookmark),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(FLucideIcons.bookmark, size: 18),
                ],
              ),
            ),
            FButton.icon(
              onPress: () => _copyAyah(context, ayah),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.ayahCopy),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(FLucideIcons.copy, size: 18),
                ],
              ),
            ),
            FButton.icon(
              onPress: onClose,
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
  }

  void _copyAyah(BuildContext context, Ayah ayah) {
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
}
