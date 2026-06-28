import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_detail_pane.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/layout/hadith_layout_scope.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_result_card.dart';

/// Single hadith result row with popover or side-panel selection behavior.
class HadithResultTile extends ConsumerWidget {
  /// Creates a result tile.
  const HadithResultTile({
    required this.hadith,
    super.key,
  });

  final DetailedHadith hadith;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = HadithResultCard(hadith: hadith);

    if (HadithLayoutScope.of(context)) return card;

    return FPopover(
      popoverBuilder: (_, _) => ConstrainedBox(
        constraints: dialogConstraints(
          context,
          preferredWidth: 620,
          preferredHeight: 620,
        ),
        child: HadithSelectedDetailsPane(hadith: hadith),
      ),
      builder: (_, controller, child) => MouseClick(
        onClick: () {
          unawaited(
            ref
                .read(hadithSessionControllerProvider.notifier)
                .selectHadith(hadith),
          );
          unawaited(controller.toggle());
        },
        child: child!,
      ),
      child: card,
    );
  }
}
