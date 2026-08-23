import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/format_byte_size.dart';
import 'package:tawaq/core/utils/reveal_folder.dart';
import 'package:tawaq/core/widgets/dialog_shell.dart';
import 'package:tawaq/feature/quran/data/sources/recitation_cache.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_reference_logic.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/surah_name_text.dart';
import 'package:tawaq/theme/theme.dart';

Future<void> showOfflineFilesDialog(BuildContext context) => showFDialog<void>(
  context: context,
  useRootNavigator: true,
  builder: (context, style, animation) => const _OfflineFilesDialog(),
);

class _OfflineFilesDialog extends HookConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.theme.colors;
    final selected = useState<Set<String>>({});
    final deleting = useState(false);
    final offline = ref.watch(recitationOfflineStoreProvider);
    final files = offline.value?.files ?? const <CachedRecitation>[];
    final totalBytes = offline.value?.totalBytes ?? 0;
    final reciters = ref.watch(recitersProvider).value ?? const [];
    final fileSetKey = files.map((file) => file.file.path).join('|');
    final reciterSetKey = reciters
        .map((reciter) => '${reciter.id}:${reciter.name}')
        .join('|');
    useEffect(() {
      // External scans/catalog refreshes start a new management session. A
      // deletion keeps its failed files selected for retry by holding this
      // reset while the operation is running.
      if (!deleting.value) selected.value = {};
      return null;
    }, [fileSetKey, reciterSetKey]);
    final mushaf = ref.read(quranMushafControllerProvider);
    final future = useMemoized(
      () =>
          Future.wait([for (final file in files) mushaf.getSurah(file.surah)]),
      [for (final file in files) file.file.path],
    );
    final metadata = useFuture(future);
    final autoSave =
        ref.watch(
          recitationSettingsProvider.select(
            (state) => state.value?.autoSaveRecitations,
          ),
        ) ??
        true;

    String reciterName(CachedRecitation file) =>
        reciters
            .where((reciter) => reciter.id == file.reciterId)
            .map((reciter) => reciter.name)
            .firstOrNull ??
        l10n.quranSelectReciter;
    String riwayah(CachedRecitation file) {
      final reciter = reciters.where((r) => r.id == file.reciterId).firstOrNull;
      return reciter?.moshaf
              .where((moshaf) => moshaf.id == file.moshafId)
              .map((moshaf) => moshaf.name)
              .firstOrNull ??
          '';
    }

    final names = <String, String>{};
    if (metadata.hasData) {
      for (var i = 0; i < files.length; i++) {
        names[files[i].file.path] = AyahReferenceLogic.surahName(
          metadata.data![i],
          files[i].surah,
          preferArabic: Localizations.localeOf(context).languageCode == 'ar',
          fallbackName: '',
        );
      }
    }
    final ordered = [...files]
      ..sort((a, b) {
        final name = (names[a.file.path] ?? '').compareTo(
          names[b.file.path] ?? '',
        );
        if (name != 0) return name;
        final reciter = reciterName(a).compareTo(reciterName(b));
        return reciter != 0 ? reciter : riwayah(a).compareTo(riwayah(b));
      });
    final targets = files
        .where((f) => selected.value.contains(f.file.path))
        .toList();

    Future<void> deleteFiles(List<CachedRecitation> targets) async {
      if (targets.isEmpty || deleting.value) return;
      final playing = ref.read(recitationControllerProvider);
      final affectsPlayback = targets.any(
        (f) =>
            playing.reciter?.id == f.reciterId &&
            playing.moshaf?.id == f.moshafId &&
            playing.surah == f.surah &&
            !playing.userStopped,
      );
      final confirmed = await _confirm(context, targets, affectsPlayback);
      if (!confirmed || !context.mounted) return;
      deleting.value = true;
      if (affectsPlayback) {
        await ref
            .read(recitationControllerProvider.notifier)
            .stopAndReleaseForOfflineDeletion();
      }
      final outcome = await ref
          .read(recitationOfflineStoreProvider.notifier)
          .deleteFiles(targets.map((f) => f.file.path));
      selected.value = {...selected.value}..removeAll(outcome.deletedPaths);
      deleting.value = false;
      if (outcome.hasFailures && context.mounted) {
        showFToast(
          context: context,
          variant: .destructive,
          icon: const Icon(FLucideIcons.triangleAlert),
          title: Text(
            l10n.quranRecitationOfflineDeleteFailed(outcome.failedPaths.length),
          ),
        );
      }
    }

    return TawaqDialogShell(
      title: l10n.quranRecitationOfflineFiles,
      icon: FLucideIcons.folder,
      width: 900,
      maxHeight: 700,
      scrollableBody: true,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                Text(l10n.quranRecitationOfflineSelected(targets.length)),
                FButton(
                  variant: .outline,
                  size: .sm,
                  onPress: deleting.value || files.isEmpty
                      ? null
                      : () => selected.value = {
                          for (final file in files) file.file.path,
                        },
                  child: Text(l10n.quranRecitationOfflineSelectAll),
                ),
                FButton(
                  variant: .ghost,
                  size: .sm,
                  onPress: deleting.value || targets.isEmpty
                      ? null
                      : () => selected.value = {},
                  child: Text(l10n.quranRecitationOfflineClearSelection),
                ),
                FButton(
                  variant: .destructive,
                  size: .sm,
                  onPress: deleting.value || targets.isEmpty
                      ? null
                      : () => unawaited(deleteFiles(targets)),
                  child: Text(l10n.quranRecitationOfflineDeleteSelected),
                ),
                FButton(
                  variant: .destructive,
                  size: .sm,
                  onPress: deleting.value || files.isEmpty
                      ? null
                      : () => unawaited(deleteFiles(files)),
                  child: Text(l10n.quranRecitationOfflineDeleteAll),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '${l10n.quranRecitationOfflineFileCount(files.length)} · ${formatByteSize(totalBytes)}',
              style: context.theme.typography.body.xs.copyWith(
                color: colors.mutedForeground,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (offline.isLoading ||
                metadata.connectionState != ConnectionState.done)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: FCircularProgress()),
              )
            else if (files.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(l10n.quranRecitationOfflineEmpty),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 640;
                  return Column(
                    children: [
                      if (wide) _header(context),
                      for (final file in ordered)
                        _row(
                          context,
                          file,
                          wide,
                          selected.value.contains(file.file.path),
                          !deleting.value,
                          reciterName(file),
                          riwayah(file),
                          names[file.file.path] ?? '',
                          (value) => selected.value = value
                              ? {...selected.value, file.file.path}
                              : ({...selected.value}..remove(file.file.path)),
                          () => unawaited(deleteFiles([file])),
                        ),
                    ],
                  );
                },
              ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.secondary,
                border: Border.all(color: colors.border),
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
                  FButton(
                    variant: .outline,
                    size: .sm,
                    prefix: const Icon(FLucideIcons.externalLink, size: 16),
                    onPress: deleting.value
                        ? null
                        : () => unawaited(_reveal(context, ref)),
                    child: Text(l10n.quranRecitationOfflineOpenFolder),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.sm),
    child: Row(
      children: [
        const SizedBox(width: 32),
        for (final label in [
          context.l10n.quranRecitationOfflineReciter,
          context.l10n.quranRecitationOfflineSurah,
          context.l10n.quranRecitationOfflineRiwayah,
          context.l10n.quranRecitationOfflineSize,
        ])
          Expanded(
            child: Text(
              label,
              style: context.theme.typography.body.xs.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ),
        const SizedBox(width: 40),
      ],
    ),
  );

  Widget _row(
    BuildContext context,
    CachedRecitation file,
    bool wide,
    bool selected,
    bool enabled,
    String reciter,
    String riwayah,
    String surah,
    ValueChanged<bool> onSelected,
    VoidCallback onDelete,
  ) {
    final text = context.theme.typography.body.sm;
    final select = FCheckbox(
      value: selected,
      enabled: enabled,
      semanticsLabel: '$reciter $surah',
      onChange: onSelected,
    );
    final delete = FTooltip(
      tipBuilder: (context, controller) =>
          Text(context.l10n.quranRecitationOfflineDelete),
      child: FButton.icon(
        variant: .ghost,
        size: .sm,
        onPress: enabled ? onDelete : null,
        child: const Icon(FLucideIcons.trash2, size: 16),
      ),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.theme.colors.secondary,
        border: Border.all(color: context.theme.colors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: wide
          ? Row(
              children: [
                SizedBox(width: 32, child: select),
                Expanded(child: Text(reciter, style: text)),
                Expanded(
                  child: Text(surah, style: textStyleForSurahName(surah, text)),
                ),
                Expanded(child: Text(riwayah, style: text)),
                Expanded(
                  child: Text(formatByteSize(file.sizeBytes), style: text),
                ),
                SizedBox(width: 40, child: delete),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                select,
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(surah, style: textStyleForSurahName(surah, text)),
                      Text(
                        '$reciter · $riwayah · ${formatByteSize(file.sizeBytes)}',
                        style: context.theme.typography.body.xs,
                      ),
                    ],
                  ),
                ),
                delete,
              ],
            ),
    );
  }

  static Future<bool> _confirm(
    BuildContext context,
    List<CachedRecitation> files,
    bool stopsPlayback,
  ) async {
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (dialogContext, style, animation) => FDialog(
        style: style,
        animation: animation,
        builder: (context, dialogStyle) => ForuiDialogLayout(
          style: dialogStyle,
          title: Text(context.l10n.quranRecitationOfflineDeleteTitle),
          body: Text(
            '${context.l10n.quranRecitationOfflineDeleteConfirm(
              files.length,
              formatByteSize(files.fold(0, (sum, file) => sum + file.sizeBytes)),
            )}${stopsPlayback ? ' ${context.l10n.quranRecitationOfflinePlaybackStops}' : ''}',
          ),
          actions: [
            FButton(
              variant: .secondary,
              onPress: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.cancel),
            ),
            FButton(
              variant: .destructive,
              onPress: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n.quranRecitationOfflineDelete),
            ),
          ],
        ),
      ),
    );
    return confirmed == true;
  }

  static Future<void> _reveal(BuildContext context, WidgetRef ref) async {
    final opened = await revealFolderInFileManager(
      (await ref.read(recitationCacheProvider).audioDirectory()).path,
    );
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
