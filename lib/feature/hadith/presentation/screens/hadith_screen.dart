import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/core/layout/split_pane_constraints.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/layout/hadith_layout_scope.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/layout/hadith_main_column.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/layout/hadith_split_layout.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Main Hadith search and exploration page.
class HadithPage extends HookConsumerWidget {
  /// Creates the Hadith page widget.
  const HadithPage({
    super.key,
    this.initialHadiths = const <DetailedHadith>[],
  });

  /// Initial hadith list used when opening the page in specific-list mode.
  final List<DetailedHadith> initialHadiths;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dorarInitProvider);
    useEffect(() {
      unawaited(
        ref
            .read(hadithSessionControllerProvider.notifier)
            .bootstrap(hadiths: initialHadiths),
      );
      return null;
    }, [initialHadiths]);

    final screenController = ref.read(hadithSessionControllerProvider.notifier);

    return AppShortcutScope(
      autofocus: true,
      shortcuts: const {
        AppShortcut.hadithResultNext,
        AppShortcut.hadithResultPrev,
      },
      handlers: {
        AppShortcut.hadithResultNext: () =>
            unawaited(screenController.selectAdjacentResult(1)),
        AppShortcut.hadithResultPrev: () =>
            unawaited(screenController.selectAdjacentResult(-1)),
      },
      child: LayoutBuilder(
        builder: (context, constraints) => HadithResponsiveBody(
          containerWidth: constraints.maxWidth,
        ),
      ),
    );
  }
}

/// Chooses split vs stacked layout from container width.
class HadithResponsiveBody extends HookConsumerWidget {
  /// Creates the responsive body for the given [containerWidth].
  const HadithResponsiveBody({required this.containerWidth, super.key});

  /// Width available to the Hadith page content.
  final double containerWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useSplitLayout = canUseHorizontalSplit(
      containerWidth: containerWidth,
      sideMin: kStudyPanelMinExtent,
      mainMin: kMainPaneMinExtent,
    );

    useEffect(
      () {
        if (!useSplitLayout) {
          final collapsed = ref.read(hadithScreenUiProvider).sidePanelCollapsed;
          if (!collapsed) {
            ref
                .read(hadithScreenSettingsProvider.notifier)
                .setSidePanelCollapsed(collapsed: true);
          }
        }
        return null;
      },
      [useSplitLayout],
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: HadithLayoutScope(
        useSplitLayout: useSplitLayout,
        child: useSplitLayout
            ? const HadithSplitLayout()
            : const HadithMainColumn(),
      ),
    );
  }
}
