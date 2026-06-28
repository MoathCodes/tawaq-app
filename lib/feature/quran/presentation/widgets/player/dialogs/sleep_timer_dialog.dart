import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/dialog_shell.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Opens the sleep-timer dialog.
Future<void> showSleepTimerDialog(BuildContext context) => showFDialog<void>(
  context: context,
  useRootNavigator: true,
  builder: (context, style, animation) => const _SleepTimerDialog(),
);

class _SleepTimerDialog extends ConsumerWidget {
  const _SleepTimerDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(
      recitationControllerProvider.select((p) => p.sleep),
    );
    final controller = ref.read(recitationControllerProvider.notifier);

    String label(RecitationSleep mode) => switch (mode) {
      RecitationSleep.off => l10n.quranRecitationSleepOff,
      RecitationSleep.endOfAyah => l10n.quranRecitationSleepEndOfAyah,
      RecitationSleep.endOfRange => l10n.quranRecitationSleepEndOfRange,
      RecitationSleep.endOfSurah => l10n.quranRecitationSleepEndOfSurah,
      RecitationSleep.after10 => l10n.quranRecitationSleepAfter('10'),
      RecitationSleep.after20 => l10n.quranRecitationSleepAfter('20'),
      RecitationSleep.after30 => l10n.quranRecitationSleepAfter('30'),
    };

    FTile sleepTile(RecitationSleep mode) => FTile(
      title: Text(label(mode)),
      suffix: mode == current ? const Icon(FLucideIcons.check) : null,
      selected: mode == current,
      onPress: () {
        controller.setSleep(mode);
        unawaited(Navigator.of(context).maybePop());
      },
    );

    // Boundary modes (off / end-of-…) are grouped apart from timed countdowns.
    const boundary = [
      RecitationSleep.off,
      RecitationSleep.endOfAyah,
      RecitationSleep.endOfRange,
      RecitationSleep.endOfSurah,
    ];
    const timed = [
      RecitationSleep.after10,
      RecitationSleep.after20,
      RecitationSleep.after30,
    ];

    return PlayerDialogShell(
      title: l10n.quranRecitationSleepTimer,
      icon: FLucideIcons.moon,
      width: 440,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FTileGroup(children: [for (final m in boundary) sleepTile(m)]),
            const SizedBox(height: AppSpacing.md),
            FTileGroup(children: [for (final m in timed) sleepTile(m)]),
          ],
        ),
      ),
    );
  }
}
