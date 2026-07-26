import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/quran/domain/models/quran_ui_models.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_ui_models.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/scale/quran_text_scale_popover.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/ayah_search_selector.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/hizb_selector.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/juz_selector.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/surah_selector.dart';
import 'package:tawaq/theme/theme.dart';

const _kSearchMinWidth = 280.0;
const _kSurahSelectMaxWidth = 200.0;

const _kInlineNavSelect = SurahSelector(inlineLabel: true);
const _kInlineJuzSelect = JuzSelector(inlineLabel: true);
const _kInlineHizbSelect = HizbSelector(inlineLabel: true);

/// Header widget for the Quran screen containing navigation controls.
class QuranHeaderWidget extends HookConsumerWidget {
  /// Creates a [QuranHeaderWidget] instance.
  const QuranHeaderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final layout = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.layout ?? QuranReadingLayout.studyMode,
      ),
    );

    final searchFocusNode = useFocusNode();
    final focusSearch = useCallback(
      searchFocusNode.requestFocus,
      [searchFocusNode],
    );
    useRegisterAppSearchFocus(focusSearch);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: NonSelectable(
        child: StaticCard(
          padding: const EdgeInsets.all(AppSpacing.sm),
          borderRadius: theme.radii.lg,
          backgroundColor: theme.colors.secondary.withAlpha(72),
          borderColor: theme.colors.border.withAlpha(96),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = isContainerAtLeast(
                context,
                constraints,
                FBreakpoint.xl,
              );
              final medium = isContainerAtLeast(
                context,
                constraints,
                FBreakpoint.md,
              );

              final layoutSegment = _LayoutSegment(
                layout: layout,
                showLabels: medium,
                onLayoutChanged: (index) => ref
                    .read(quranScreenSettingsProvider.notifier)
                    .setLayout(QuranReadingLayout.values[index]),
              );

              final displayTools = _DisplayToolsRow(
                layoutSegment: layoutSegment,
              );

              final navigation = _QuranLocationRail(
                stacked: !medium,
              );

              final search = _HeaderSearchField(
                focusNode: searchFocusNode,
              );

              if (wide) {
                return Row(
                  children: [
                    displayTools,
                    const _HeaderDivider(),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: _kSearchMinWidth,
                        ),
                        child: search,
                      ),
                    ),
                    const _HeaderDivider(),
                    Expanded(child: navigation),
                  ],
                );
              }

              if (medium) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.sm,
                  children: [
                    Row(
                      children: [
                        displayTools,
                        const _HeaderDivider(),
                        Expanded(child: navigation),
                      ],
                    ),
                    search,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.sm,
                children: [
                  displayTools,
                  navigation,
                  search,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DisplayToolsRow extends StatelessWidget {
  const _DisplayToolsRow({required this.layoutSegment});

  final Widget layoutSegment;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: [
        layoutSegment,
        const QuranTextScalePopover(),
      ],
    );
  }
}

class _QuranLocationRail extends StatelessWidget {
  const _QuranLocationRail({required this.stacked});

  final bool stacked;

  @override
  Widget build(BuildContext context) {
    return stacked ? _buildStacked() : _buildRow();
  }

  Widget _buildRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 3,
      children: [
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kSurahSelectMaxWidth),
            child: _kInlineNavSelect,
          ),
        ),
        const _RailHairline(axis: Axis.vertical),
        const Flexible(
          child: _kInlineJuzSelect,
        ),
        const _RailHairline(axis: Axis.vertical),
        const Flexible(
          child: _kInlineHizbSelect,
        ),
      ],
    );
  }

  Widget _buildStacked() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 3,
      children: [
        _kInlineNavSelect,
        _RailHairline(axis: Axis.horizontal),
        Row(
          spacing: 3,
          children: [
            Expanded(child: _kInlineJuzSelect),
            _RailHairline(axis: Axis.vertical),
            Expanded(child: _kInlineHizbSelect),
          ],
        ),
      ],
    );
  }
}

class _RailHairline extends StatelessWidget {
  const _RailHairline({required this.axis});

  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final color = context.theme.colors.border.withValues(alpha: 0.55);

    if (axis == Axis.vertical) {
      return SizedBox(
        height: 30,
        child: VerticalDivider(
          width: 1,
          thickness: 1,
          color: color,
        ),
      );
    }

    return Divider(
      height: 1,
      thickness: 1,
      color: color,
    );
  }
}

class _HeaderSearchField extends StatelessWidget {
  const _HeaderSearchField({required this.focusNode});

  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return AyahSearchSelector(
      showLabel: false,
      focusNode: focusNode,
    );
  }
}

class _HeaderDivider extends StatelessWidget {
  const _HeaderDivider();

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: SizedBox(
        height: 28,
        child: VerticalDivider(
          width: 1,
          thickness: 1,
          color: colors.border.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}

class _LayoutSegment extends StatelessWidget {
  const _LayoutSegment({
    required this.layout,
    required this.showLabels,
    required this.onLayoutChanged,
  });

  final QuranReadingLayout layout;
  final bool showLabels;
  final ValueChanged<int> onLayoutChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: colors.muted.withValues(alpha: 0.45),
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: colors.border.withValues(alpha: 0.8)),
          borderRadius: theme.radii.md,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            for (final mode in QuranReadingLayout.values)
              _LayoutOption(
                mode: mode,
                label: mode.getLocaleName(l10n),
                selected: layout == mode,
                showLabel: showLabels,
                onPress: () => onLayoutChanged(mode.index),
              ),
          ],
        ),
      ),
    );
  }
}

class _LayoutOption extends StatelessWidget {
  const _LayoutOption({
    required this.mode,
    required this.label,
    required this.selected,
    required this.showLabel,
    required this.onPress,
  });

  final QuranReadingLayout mode;
  final String label;
  final bool selected;
  final bool showLabel;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final buttonStyle = layoutSegmentButtonStyle(
      colors: theme.colors,
      typography: theme.typography,
      style: theme.style,
      borderRadius: theme.radii.sm,
      compact: !showLabel,
    );

    return QuranSemantics.mergedChip(
      child: showLabel
          ? FButton(
              mainAxisSize: MainAxisSize.min,
              selected: selected,
              semanticsLabel: label,
              onPress: onPress,
              style: buttonStyle,
              prefix: Icon(mode.icon),
              child: Text(label),
            )
          : FButton.icon(
              selected: selected,
              semanticsLabel: label,
              onPress: onPress,
              style: buttonStyle,
              child: Icon(mode.icon),
            ),
    );
  }
}
