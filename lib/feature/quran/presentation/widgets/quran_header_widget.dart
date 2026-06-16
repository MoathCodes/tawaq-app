import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:forui_hooks/forui_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/use_register_app_search_focus.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/quran/domain/models/quran_layouts.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_layout_ui.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/scale/quran_text_scale_popover.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/ayah_search_selector.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/juz_selector.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/surah_selector.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Header widget for the Quran screen containing navigation controls.
class QuranHeaderWidget extends HookConsumerWidget {
  /// Creates a [QuranHeaderWidget] instance.
  const QuranHeaderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final borderColor = theme.colors.border;
    final layout = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.layout ?? QuranReadingLayout.studyMode,
      ),
    );

    final searchPopover = useFPopoverController(
      vsync: useSingleTickerProvider(),
    );
    final openSearch = useCallback(
      () => unawaited(searchPopover.show()),
      [searchPopover],
    );
    useRegisterAppSearchFocus(openSearch);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: NonSelectable(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < theme.breakpoints.lg;

            final tabs = _LayoutTabs(
              layout: layout,
              compact: compact,
              onLayoutChanged: (v) => ref
                  .read(quranScreenSettingsProvider.notifier)
                  .setLayout(QuranReadingLayout.values[v]),
            );

            final scaleControl = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                QuranSemantics.decorative(
                  Container(
                    height: 24,
                    width: 1,
                    color: borderColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const QuranTextScalePopover(),
              ],
            );

            final selectors = Row(
              children: [
                const Expanded(
                  flex: 15,
                  child: SurahSelector(),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  flex: 20,
                  child: JuzSelector(),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  flex: 36,
                  child: AyahSearchSelector(
                    searchPopoverController: searchPopover,
                  ),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: tabs),
                      scaleControl,
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  selectors,
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 28, child: tabs),
                const SizedBox(width: AppSpacing.xl),
                Expanded(flex: 71, child: selectors),
                const SizedBox(width: AppSpacing.xl),
                scaleControl,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LayoutTabs extends StatelessWidget {
  const _LayoutTabs({
    required this.layout,
    required this.compact,
    required this.onLayoutChanged,
  });

  final QuranReadingLayout layout;
  final bool compact;
  final ValueChanged<int> onLayoutChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FTabs(
      control: FTabControl.lifted(
        index: layout.index,
        onChange: onLayoutChanged,
      ),
      style: const .delta(
        padding: .value(EdgeInsets.all(2)),
        indicatorSize: FTabBarIndicatorSize.tab,
      ),
      children: [
        for (final mode in QuranReadingLayout.values)
          FTabEntry(
            label: QuranSemantics.mergedChip(
              child: Row(
                mainAxisAlignment: .center,
                spacing: 4,
                children: [
                  QuranSemantics.decorative(Icon(mode.icon)),
                  if (!compact) Text(mode.getLocaleName(l10n)),
                ],
              ),
            ),
            child: const SizedBox.shrink(),
          ),
      ],
    );
  }
}
