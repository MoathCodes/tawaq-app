import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/format_byte_size.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_sleep.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/offline_files_dialog.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/range_repeat_dialog.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/sleep_timer_dialog.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_drawer_header.dart';
import 'package:tawaq/theme/theme.dart';

/// Offline files, range/repeat, and sleep timer tiles in the drawer.
class RecitationDrawerActionsSection extends ConsumerWidget {
  /// Creates the actions section.
  const RecitationDrawerActionsSection({
    required this.rangeLabel,
    required this.rangeWidget,
    required this.surahName,
    required this.repeatSuffix,
    super.key,
  });

  final String rangeLabel;
  final Widget? rangeWidget;
  final String surahName;
  final String repeatSuffix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final playback = ref.watch(recitationControllerProvider);

    final sleepLabel = switch (playback.sleep) {
      RecitationSleep.off => l10n.quranRecitationSleepOff,
      RecitationSleep.endOfAyah => l10n.quranRecitationSleepEndOfAyah,
      RecitationSleep.endOfRange => l10n.quranRecitationSleepEndOfRange,
      RecitationSleep.endOfSurah => l10n.quranRecitationSleepEndOfSurah,
      RecitationSleep.after10 => l10n.quranRecitationSleepAfter('10'),
      RecitationSleep.after20 => l10n.quranRecitationSleepAfter('20'),
      RecitationSleep.after30 => l10n.quranRecitationSleepAfter('30'),
    };

    return FTileGroup(
      children: [
        FTile(
          prefix: const Icon(FLucideIcons.folder),
          title: Text(l10n.quranRecitationOfflineFiles),
          subtitle: RecitationDrawerCacheSizeSubtitle(
            bytesAsync: ref.watch(totalCacheBytesProvider),
          ),
          onPress: () => showOfflineFilesDialog(context),
        ),
        FTile(
          prefix: const Icon(FLucideIcons.repeat),
          title: Text(l10n.quranRecitationRangeRepeat),
          subtitle: rangeWidget != null
              ? RecitationDrawerRangeSubtitle(
                  rangeLabel: rangeLabel,
                  suffix: repeatSuffix,
                )
              : Text(surahName),
          onPress: () => showRangeRepeatDialog(context),
        ),
        FTile(
          prefix: const Icon(FLucideIcons.moon),
          title: Text(l10n.quranRecitationSleepTimer),
          subtitle: Text(sleepLabel),
          onPress: () => showSleepTimerDialog(context),
        ),
      ],
    );
  }
}

class RecitationDrawerCacheSizeSubtitle extends StatelessWidget {
  const RecitationDrawerCacheSizeSubtitle({required this.bytesAsync, super.key});

  final AsyncValue<int> bytesAsync;

  @override
  Widget build(BuildContext context) {
    final bytes = bytesAsync.value ?? 0;
    return Text(formatByteSize(bytes));
  }
}
