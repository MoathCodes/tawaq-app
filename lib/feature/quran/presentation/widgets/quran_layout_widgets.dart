import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';
import 'package:hasanat/feature/quran/domain/models/font_sizes.dart';
import 'package:hasanat/feature/quran/presentation/widgets/study_panel.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

/// Single page layout for the Quran reader.
class SinglePageLayout extends ConsumerWidget {
  /// Creates a [SinglePageLayout] instance.
  const SinglePageLayout({
    required this.controller,
    required this.buildStyle,
    required this.theme,
    required this.onPageChanged,
    required this.onAyahTapped,
    super.key,
  });

  /// The mushaf reader controller.
  final MushafReaderController controller;

  /// Function to build the mushaf style.
  final MushafStyle Function(FThemeData, [FontSizes]) buildStyle;

  /// The theme data.
  final FThemeData theme;

  /// Callback when page changes.
  final void Function(MushafPageInfo) onPageChanged;

  /// Callback when an ayah is tapped.
  final void Function(Ayah) onAyahTapped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(
      stateSettingsProvider.select(
        (v) => v.value?.quranState.fontSize ?? FontSizes.medium,
      ),
    );
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => unawaited(
          controller.animateToPage(controller.currentPage + 1),
        ),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => unawaited(
          controller.animateToPage(controller.currentPage - 1),
        ),
        const SingleActivator(LogicalKeyboardKey.space): () => unawaited(
          controller.animateToPage(controller.currentPage + 1),
        ),
      },
      child: Focus(
        autofocus: true,
        child: StaticCard(
          child: MushafReader(
            controller: controller,
            onAyahTap: onAyahTapped,
            style: buildStyle(theme, fontSize),
            onPageChanged: onPageChanged,
          ),
        ),
      ),
    );
  }
}

/// Double page layout for the Quran reader.
class DoublePageLayout extends ConsumerWidget {
  /// Creates a [DoublePageLayout] instance.
  const DoublePageLayout({
    required this.controller,
    required this.buildStyle,
    required this.theme,
    required this.onPageChanged,
    required this.onAyahTapped,
    super.key,
  });

  /// The mushaf reader controller.
  final MushafReaderController controller;

  /// Function to build the mushaf style.
  final MushafStyle Function(FThemeData, [FontSizes]) buildStyle;

  /// The theme data.
  final FThemeData theme;

  /// Callback when page changes.
  final void Function(MushafPageInfo) onPageChanged;

  /// Callback when an ayah is tapped.
  final void Function(Ayah) onAyahTapped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(
      stateSettingsProvider.select(
        (v) => v.value?.quranState.fontSize ?? FontSizes.medium,
      ),
    );
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => unawaited(
          controller.animateToPage(controller.currentPage + 1),
        ),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => unawaited(
          controller.animateToPage(controller.currentPage - 1),
        ),
        const SingleActivator(LogicalKeyboardKey.space): () => unawaited(
          controller.animateToPage(controller.currentPage + 1),
        ),
      },
      child: Focus(
        autofocus: true,
        child: StaticCard(
          child: MushafTwoPageReader(
            key: ValueKey(
              'two-page-${theme.colors.secondaryForeground.hashCode}',
            ),
            controller: controller,
            style: buildStyle(theme, fontSize),
            onAyahTap: onAyahTapped,
            onPageChanged: (info) => onPageChanged(info.$1),
          ),
        ),
      ),
    );
  }
}

/// Study mode layout for the Quran reader with a side panel.
class StudyModeLayout extends StatelessWidget {
  /// Creates a [StudyModeLayout] instance.
  const StudyModeLayout({
    required this.buildStyle,
    required this.theme,
    required this.controller,
    required this.onPageChanged,
    required this.onAyahTapped,
    super.key,
  });

  /// Function to build the mushaf style.
  final MushafStyle Function(FThemeData, [FontSizes]) buildStyle;

  /// The theme data.
  final FThemeData theme;

  /// The mushaf reader controller.
  final MushafReaderController controller;

  /// Callback when page changes.
  final void Function(MushafPageInfo) onPageChanged;

  /// Callback when an ayah is tapped.
  final void Function(Ayah) onAyahTapped;

  @override
  Widget build(BuildContext context) {
    const panelWidth = 350.0;
    const spacer = 20.0;

    // Study panel with navigation logic built-in
    final panel = RepaintBoundary(
      child: Directionality(
        textDirection: Directionality.of(context),
        child: StudyPanel(controller: controller),
      ),
    );
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return LayoutBuilder(
      builder: (_, constraints) {
        final quranWidth = constraints.maxWidth - panelWidth - spacer;

        // Mushaf reader content with isolated font size rebuild
        final content = StaticCard(
          child: Center(
            child: Consumer(
              builder: (context, ref, child) {
                final fontSize = ref.watch(
                  stateSettingsProvider.select(
                    (v) => v.value?.quranState.fontSize ?? FontSizes.medium,
                  ),
                );
                return MushafReader(
                  controller: controller,
                  style: buildStyle(theme, fontSize),
                  onPageChanged: onPageChanged,
                  onAyahTap: onAyahTapped,
                );
              },
            ),
          ),
        );

        return Directionality(
          textDirection: TextDirection.ltr,
          child: FResizable(
            axis: Axis.horizontal,
            children: [
              FResizableRegion.region(
                initialExtent: isArabic ? quranWidth : panelWidth,
                minExtent: isArabic ? null : 250,
                builder: (_, _, _) => Align(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: isArabic ? content : panel,
                  ),
                ),
              ),
              FResizableRegion.region(
                initialExtent: isArabic ? panelWidth : quranWidth,
                minExtent: isArabic ? 250 : null,
                builder: (_, _, _) => Align(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: isArabic ? panel : content,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
