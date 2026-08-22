import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/format_byte_size.dart';
import 'package:tawaq/core/utils/reveal_folder.dart';
import 'package:tawaq/core/widgets/dialog_shell.dart';
import 'package:tawaq/feature/quran/data/sources/recitation_cache.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_reference_logic.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/surah_name_text.dart';
import 'package:tawaq/theme/theme.dart';

/// Opens the offline files manager dialog.
Future<void> showOfflineFilesDialog(BuildContext context) => showFDialog<void>(
  context: context,
  useRootNavigator: true,
  builder: (context, style, animation) => const _OfflineFilesDialog(),
);

class _OfflineFilesDialog extends ConsumerWidget {
  const _OfflineFilesDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final filesAsync = ref.watch(
      recitationOfflineStoreProvider.select(
        (state) => (
          isLoading: state.isLoading,
          error: state.error,
          files: state.value?.files ?? const <CachedRecitation>[],
          totalBytes: state.value?.totalBytes ?? 0,
        ),
      ),
    );
    final reciters = ref.watch(recitersProvider).value ?? const <Reciter>[];
    final mushaf = ref.read(quranMushafControllerProvider);
    final autoSave =
        ref.watch(
          recitationSettingsProvider.select(
            (s) => s.value?.autoSaveRecitations,
          ),
        ) ??
        true;

    final files = filesAsync.files;
    final totalBytes = filesAsync.totalBytes;

    String reciterName(int id) {
      for (final r in reciters) {
        if (r.id == id) return r.name;
      }
      return l10n.quranSelectReciter;
    }

    String riwayahName(int reciterId, int moshafId) {
      for (final r in reciters) {
        if (r.id != reciterId) continue;
        for (final m in r.moshaf) {
          if (m.id == moshafId) return m.name;
        }
      }
      return '';
    }

    Widget fileTitle(CachedRecitation f) {
      final surahName = AyahReferenceLogic.surahName(
        mushaf.getSurahSync(f.surah),
        f.surah,
        preferArabic: Localizations.localeOf(context).languageCode == 'ar',
        fallbackName: '',
      );
      final riwayah = riwayahName(f.reciterId, f.moshafId);
      final titleStyle = typography.body.sm.copyWith(color: colors.foreground);
      return Text.rich(
        TextSpan(
          style: titleStyle,
          children: [
            TextSpan(text: '${reciterName(f.reciterId)} · '),
            if (surahName.isNotEmpty)
              TextSpan(
                text: surahName,
                style: textStyleForSurahName(surahName, titleStyle),
              ),
            if (riwayah.isNotEmpty) TextSpan(text: ' · $riwayah'),
          ],
        ),
      );
    }

    Future<void> deleteFile(CachedRecitation f) async {
      await ref
          .read(recitationOfflineStoreProvider.notifier)
          .delete(f.file.path);
    }

    return TawaqDialogShell(
      title: l10n.quranRecitationOfflineFiles,
      icon: FLucideIcons.folder,
      maxHeight: 660,
      scrollableBody: true,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.07),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.25),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FSwitch(
                    leadingLabel: true,
                    label: Text(l10n.quranRecitationOfflineAutoSave),
                    value: autoSave,
                    onChange: (value) => ref
                        .read(recitationSettingsProvider.notifier)
                        .setAutoSaveRecitations(value: value),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    autoSave
                        ? l10n.quranRecitationOfflineAutoSaveOnHint
                        : l10n.quranRecitationOfflineAutoSaveOffHint,
                    style: typography.body.xs.copyWith(
                      color: colors.foreground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FButton(
              variant: .outline,
              prefix: const Icon(FLucideIcons.externalLink, size: 16),
              onPress: () => unawaited(_revealAudioFolder(context, ref)),
              child: Text(l10n.quranRecitationOfflineOpenFolder),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.quranRecitationOfflineInFolder,
                  style: typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
                Text(
                  l10n.quranRecitationOfflineFileCount(files.length),
                  style: typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (files.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  l10n.quranRecitationOfflineEmpty,
                  style: typography.body.sm.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              )
            else
              FTileGroup(
                children: [
                  for (final f in files)
                    FTile(
                      prefix: const Icon(FLucideIcons.fileAudio),
                      title: fileTitle(f),
                      subtitle: Text(formatByteSize(f.sizeBytes)),
                      suffix: FTappable(
                        onPress: () => unawaited(deleteFile(f)),
                        child: const Icon(FLucideIcons.trash2),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.secondary,
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.quranRecitationOfflineStorageUsed,
                    style: typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                  Text(
                    formatByteSize(totalBytes),
                    style: typography.body.sm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.foreground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _revealAudioFolder(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final dir = await ref.read(recitationCacheProvider).audioDirectory();
    final opened = await revealFolderInFileManager(dir.path);
    if (!opened && context.mounted) {
      showFToast(
        context: context,
        variant: .destructive,
        icon: const Icon(FLucideIcons.triangleAlert),
        title: Text(context.l10n.openFolderFailed),
      );
    }
  }
}
