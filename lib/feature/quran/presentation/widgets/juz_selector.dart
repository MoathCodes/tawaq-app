import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/widgets/f_skeletonizer.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/l10n/app_localizations.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

/// Juz selector that only rebuilds when juz number changes.
class JuzSelector extends HookConsumerWidget {
  /// Creates a [JuzSelector] instance.
  const JuzSelector({required this.controller, super.key});

  /// The mushaf reader controller.
  final MushafReaderController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allJuzs = useFuture(
      useMemoized(controller.getJuzs),
    );

    // Use Riverpod state for current page info
    final currentJuzNumber = ref.watch(
      stateSettingsProvider.select(
        (v) => v.value?.quranState.pageInfo.juzNumber,
      ),
    );
    final selectedJuz = allJuzs.hasData && currentJuzNumber != null
        ? allJuzs.data?.firstWhere(
            (e) => e.number == currentJuzNumber,
            orElse: () => allJuzs.data!.first,
          )
        : null;

    return SizedBox(
      width: 200,
      child: FSkeletonizer(
        enabled: allJuzs.connectionState == ConnectionState.waiting,
        child: FSelect<Juz>.searchBuilder(
          style: selectStyle(
            colors: context.theme.colors,
            style: context.theme.style,
            typography: context.theme.typography,
            useQuranFont: true,
          ).call,
          control: FSelectControl.lifted(
            value: selectedJuz,
            onChange: (v) async {
              if (v != null) {
                await controller.jumpToJuz(v.number);
              }
            },
          ),
          format: (v) => v.glyph,
          filter: (q) {
            return allJuzs.hasData
                ? allJuzs.data!.where((e) => e.number.toString().contains(q))
                : [];
          },
          contentBuilder: (_, _, vals) => vals
              .map(
                (v) => FSelectItem<Juz>(
                  value: v,
                  title: Text(
                    v.glyph,
                    style: const TextStyle(
                      fontFamily: 'QCF4_BSML',
                      package: 'mushaf_reader',
                      fontSize: 36,
                    ),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!.juzLabel(v.number),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
