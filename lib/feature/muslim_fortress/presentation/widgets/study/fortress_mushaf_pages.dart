import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/fortress_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/domain/models/quran_text_scale.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_mushaf_style.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Embeds one or more mushaf pages inside scrollable thikr content.
class FortressMushafPages extends ConsumerWidget {
  /// Creates an embedded mushaf pages block.
  const FortressMushafPages({
    required this.pages,
    required this.loadingWidget,
    super.key,
  });

  static const _referenceWidth = 500.0;

  static const _referenceHeight = 850.0;

  /// Mushaf page numbers to display (1–604).
  final List<int> pages;

  /// Shown while a page loads.
  final Widget loadingWidget;

  static const _maxViewportHeightFraction = 0.55;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final controller = ref.watch(fortressMushafControllerProvider);
    final quranTextScale = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.quranTextScale ?? QuranTextScale.medium,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final paneHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final maxPageHeight = paneHeight * _maxViewportHeightFraction;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < pages.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.lg),
              QuranSemantics.mushafReadingRegion(
                label: context.l10n.pageLabel(pages[i]),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxPageHeight),
                  child: AspectRatio(
                    aspectRatio: _referenceWidth / _referenceHeight,
                    child: MushafPage(
                      page: pages[i],
                      controller: controller,
                      hideHeader: true,
                      enableAyahHighlight: false,
                      loadingWidget: loadingWidget,
                      style: buildQuranMushafStyle(theme, quranTextScale),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
