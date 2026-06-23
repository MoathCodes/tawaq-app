import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/core/widgets/dialog_shell.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_equalizer.dart';
import 'package:tawaq/theme/theme.dart';

/// Opens the playback queue dialog (the timed ayahs of the current selection).
Future<void> showQueueDialog(BuildContext context) => showFDialog<void>(
  context: context,
  builder: (context, _, _) => const _QueueDialog(),
);

class _QueueDialog extends ConsumerWidget {
  const _QueueDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.theme.colors;
    final playback = ref.watch(recitationControllerProvider);
    final controller = ref.read(recitationControllerProvider.notifier);
    final timing = controller.currentTiming;

    // The ayahs in scope: the selected range, or every timed ayah of the surah.
    final ayat = <AyahTiming>[
      if (timing != null)
        for (final a in timing.ayat)
          if (a.ayah > 0 &&
              (!playback.isRange ||
                  (a.ayah >= playback.rangeStart! &&
                      a.ayah <= playback.rangeEnd!)))
            a,
    ];

    return PlayerDialogShell(
      title: l10n.quranRecitationQueue,
      icon: FLucideIcons.listMusic,
      width: 440,
      maxHeight: 660,
      scrollableBody: ayat.isNotEmpty,
      child: ayat.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                l10n.quranRecitationQueueEmpty,
                textAlign: TextAlign.center,
                style: context.theme.typography.body.sm.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ayat.length,
                    itemBuilder: (context, index) {
                      final a = ayat[index];
                      return FTile(
                        prefix: a.ayah == playback.currentAyah
                            ? RecitationEqualizer(color: colors.primary)
                            : null,
                        title: Text('${l10n.ayahLabel} ${a.ayah}'),
                        details: Text(_clip(a.endMs - a.startMs)),
                        selected: a.ayah == playback.currentAyah,
                        onPress: () {
                          unawaited(
                            controller.seekTo(
                              Duration(milliseconds: a.startMs),
                            ),
                          );
                          unawaited(Navigator.of(context).maybePop());
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: FButton(
                    variant: .outline,
                    onPress: () {
                      unawaited(controller.stop());
                      unawaited(Navigator.of(context).maybePop());
                    },
                    child: Text(l10n.quranRecitationQueueClear),
                  ),
                ),
              ],
            ),
    );
  }

  /// Formats a clip length in milliseconds as `m:ss`.
  static String _clip(int ms) {
    final d = Duration(milliseconds: ms);
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '${d.inMinutes}:$seconds';
  }
}
