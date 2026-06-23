import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/layout/lazy_tab_content.dart';
import 'package:tawaq/core/layout/persisted_horizontal_split_pane.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/layout/split_extent_resolver.dart';
import 'package:tawaq/core/layout/split_pane_constraints.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/empty_state_panel.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_flow_state.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_locale_extensions.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_screen_state.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_search_state.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_detail_pane.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_accessibility.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_result_card.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

part 'hadith_screen_filters.dart';
part 'hadith_screen_layout.dart';
part 'hadith_screen_results.dart';

/// Exposes whether the Hadith page is using a horizontal split layout.
class _HadithLayoutScope extends InheritedWidget {
  const _HadithLayoutScope({
    required this.useSplit,
    required super.child,
  });

  final bool useSplit;

  static bool useSplitOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_HadithLayoutScope>()
          ?.useSplit ??
      false;

  @override
  bool updateShouldNotify(_HadithLayoutScope oldWidget) =>
      useSplit != oldWidget.useSplit;
}

class _HadithResponsiveBody extends HookConsumerWidget {
  const _HadithResponsiveBody({required this.containerWidth});

  final double containerWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useSplit = canUseHorizontalSplit(
      containerWidth: containerWidth,
      sideMin: kStudyPanelMinExtent,
      mainMin: kMainPaneMinExtent,
    );

    useEffect(
      () {
        if (!useSplit) {
          final collapsed = ref.read(hadithSidePanelCollapsedProvider);
          if (!collapsed) {
            ref
                .read(hadithScreenSettingsProvider.notifier)
                .setSidePanelCollapsed(collapsed: true);
          }
        }
        return null;
      },
      [useSplit],
    );

    return _HadithLayoutScope(
      useSplit: useSplit,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: useSplit
            ? const _DesktopSplitLayout()
            : const Column(
                children: [
                  _SearchHeader(),
                  SizedBox(height: AppSpacing.lg),
                  Expanded(child: _ResultsList()),
                ],
              ),
      ),
    );
  }
}

/// Main Hadith search and exploration page.
class HadithPage extends HookConsumerWidget {
  /// Creates the Hadith page widget.
  const HadithPage({
    super.key,
    this.initialHadiths = const <DetailedHadith>[],
  });

  /// Initial hadith list used when opening the page in specific-list mode.
  final List<DetailedHadith> initialHadiths;

  static const _filterPopoverGroupId = 'hadith-filter-popover';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dorarInitProvider);
    useEffect(() {
      unawaited(
        ref
            .read(hadithScreenControllerProvider.notifier)
            .bootstrap(hadiths: initialHadiths),
      );
      return null;
    }, [initialHadiths]);

    final screenController = ref.read(hadithScreenControllerProvider.notifier);

    final page = LayoutBuilder(
      builder: (context, constraints) => _HadithResponsiveBody(
        containerWidth: constraints.maxWidth,
      ),
    );

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
      child: page,
    );
  }
}
