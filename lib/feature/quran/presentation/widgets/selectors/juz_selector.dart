import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Juz selector that only rebuilds when juz number changes.
class JuzSelector extends HookConsumerWidget {
  /// Creates a [JuzSelector] instance.
  const JuzSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(quranMushafControllerProvider);
    final theme = context.theme;
    final l10n = context.l10n;
    final allJuzs = useFuture(
      useMemoized(controller.getJuzs),
    );

    // Use Riverpod state for current page info
    final currentJuzNumber = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.pageInfo.juzNumber,
      ),
    );
    final selectedJuz = allJuzs.hasData && currentJuzNumber != null
        ? allJuzs.data?.firstWhere(
            (e) => e.number == currentJuzNumber,
            orElse: () => allJuzs.data!.first,
          )
        : null;

    final selectorReady =
        allJuzs.connectionState == ConnectionState.done && allJuzs.hasData;
    final juzFieldName = QuranSemantics.juzFieldName(l10n);

    return FSkeletonizer(
      enabled: allJuzs.connectionState == ConnectionState.waiting,
      child: QuranSemantics.labeledControl(
        name: juzFieldName,
        value: selectedJuz != null ? l10n.juzLabel(selectedJuz.number) : null,
        enabled: selectorReady,
        excludeChild: true,
        child: FSelect<Juz>.searchBuilder(
          enabled: selectorReady,
          label: Text(juzFieldName),
          contentConstraints: selectPopoverPortalConstraints(context),
          style: selectStyle(
            colors: theme.colors,
            style: theme.style,
            typography: theme.typography,
          ),
          control: FSelectControl.lifted(
          value: selectedJuz,
          onChange: (v) async {
            if (v != null) {
              await controller.jumpToJuz(v.number);
            }
          },
        ),
        format: (v) => l10n.juzLabel(v.number),
        filter: (q) {
          return allJuzs.hasData
              ? allJuzs.data!.where((e) => e.number.toString().contains(q))
              : [];
        },
        contentBuilder: (_, _, vals) => vals
            .map(
              (v) => FSelectItem<Juz>(
                value: v,
                title: QuranSemantics.mergedChip(
                  child: Row(
                    children: [
                      QuranSemantics.decorative(
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            v.glyph,
                            style: const TextStyle(
                              fontFamily: 'QCF4_BSML',
                              package: 'mushaf_reader',
                              fontSize: 36,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.juzLabel(v.number)),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
        ),
      ),
    );
  }
}
