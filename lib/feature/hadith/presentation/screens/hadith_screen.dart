import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/layout/persisted_horizontal_split_pane.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/layout/split_pane_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/use_register_app_search_focus.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_flow_state.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_identity.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_locale_extensions.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_screen_state.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_search_state.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_detail_pane.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_accessibility.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_result_card.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

part 'hadith_screen_filters.dart';
part 'hadith_screen_layout.dart';
part 'hadith_screen_results.dart';

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
    useEffect(() {
      unawaited(
        ref
            .read(hadithScreenControllerProvider.notifier)
            .bootstrap(hadiths: initialHadiths),
      );
      return null;
    }, [initialHadiths]);

    final desktop = isAtLeast(context, FBreakpoint.lg);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: desktop
          ? const _DesktopSplitLayout()
          : const Column(
              children: [
                _SearchHeader(
                  desktop: false,
                  groupId: _filterPopoverGroupId,
                ),
                SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: _ResultsList(enableDetailsPopover: true),
                ),
              ],
            ),
    );
  }
}
