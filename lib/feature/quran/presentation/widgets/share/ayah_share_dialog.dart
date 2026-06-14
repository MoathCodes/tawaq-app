import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/clipboard_image.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/core/utils/widget_to_image.dart';
import 'package:tawaq/feature/quran/domain/models/quran_text_scale.dart';
import 'package:tawaq/feature/quran/presentation/extensions/ayah_reference_formatter.dart';
import 'package:tawaq/feature/quran/presentation/models/ayah_share_include.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_mushaf_style.dart';
import 'package:tawaq/feature/quran/presentation/widgets/share/ayah_share_card.dart';
import 'package:tawaq/feature/quran/presentation/widgets/share/ayah_share_include_panel.dart';
import 'package:tawaq/feature/quran/presentation/widgets/share/ayah_share_range_slider.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

Future<AyahSharePageReferences> _loadPageAyahReferences(
  MushafReaderController controller,
  List<int> ayahIds, {
  required bool isArabic,
  required AppLocalizations l10n,
}) async {
  final orderedAyahs = <Ayah>[];
  for (final id in ayahIds) {
    orderedAyahs.add(await controller.getAyah(id));
  }

  final singleSurahPage = isSingleSurahPage(orderedAyahs);
  final full = <int, String>{};
  final compact = <int, String>{};

  for (var i = 0; i < orderedAyahs.length; i++) {
    final ayah = orderedAyahs[i];
    full[ayah.ayahId] = localizedAyahReference(
      ayah: ayah,
      controller: controller,
      l10n: l10n,
      isArabic: isArabic,
    );
    compact[ayah.ayahId] = localizedCompactAyahReference(
      ayah: ayah,
      indexOnPage: i,
      orderedAyahs: orderedAyahs,
      controller: controller,
      l10n: l10n,
      isArabic: isArabic,
      singleSurahPage: singleSurahPage,
    );
  }

  return AyahSharePageReferences(
    full: full,
    compact: compact,
    labeledMarkIndices: sliderMarkLabelIndices(orderedAyahs),
  );
}

/// Opens the ayah share dialog for exporting verses as an image.
Future<void> showAyahShareDialog(
  BuildContext context, {
  required MushafReaderController controller,
  required Ayah ayah,
}) {
  return showFDialog<void>(
    context: context,
    builder: (context, style, animation) => AyahShareDialog(
      controller: controller,
      ayah: ayah,
    ),
  );
}

/// Dialog for configuring and exporting a verse range as a shareable image.
class AyahShareDialog extends HookConsumerWidget {
  /// Creates the share dialog.
  const AyahShareDialog({
    required this.controller,
    required this.ayah,
    super.key,
  });

  final MushafReaderController controller;
  final Ayah ayah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final boundaryKey = useMemoized(GlobalKey.new);
    final textScale = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.quranTextScale ?? QuranTextScale.medium,
      ),
    );
    final mushafStyle = buildQuranMushafStyle(theme, textScale);

    final pageSnapshot = useFuture(
      useMemoized(() => controller.getPage(ayah.page), [ayah.page]),
    );

    final included = useState<Set<AyahShareInclude>>({
      AyahShareInclude.surahHeader,
      AyahShareInclude.basmalah,
      AyahShareInclude.appName,
    });
    final isCapturing = useState(false);

    final page = pageSnapshot.data;
    final pageAyahIds = page == null
        ? <int>[]
        : MushafPageRangeLayout.orderedAyahIdsOnPage(page);
    final referenceSnapshot = useFuture(
      useMemoized(
        () => _loadPageAyahReferences(
          controller,
          pageAyahIds,
          isArabic: isArabic,
          l10n: l10n,
        ),
        [pageAyahIds.join(','), isArabic],
      ),
    );
    final fallbackFullReference = localizedAyahReference(
      ayah: ayah,
      controller: controller,
      l10n: l10n,
      isArabic: isArabic,
    );
    final fallbackCompactReference = localizedAyahNumber(
      l10n,
      ayah.numberInSurah,
    );
    final pageReferences =
        referenceSnapshot.data ??
        AyahSharePageReferences(
          full: {ayah.ayahId: fallbackFullReference},
          compact: {ayah.ayahId: fallbackCompactReference},
          labeledMarkIndices: {0},
        );
    final selectedIndex = pageAyahIds.indexOf(ayah.ayahId);

    final selectedAyahIds = useState<List<int>>([ayah.ayahId]);

    final basmalahAvailable =
        page != null &&
        MushafPageRangeLayout.basmalahPossible(page, selectedAyahIds.value);
    final lineBreaksToggleAvailable =
        page != null &&
        MushafPageRangeLayout.newlinesWouldCompact(
          page,
          selectedAyahIds.value,
        );
    final defaultsApplied = useRef(false);

    useEffect(() {
      if (page == null) return null;

      final basmalahAvail = MushafPageRangeLayout.basmalahPossible(
        page,
        selectedAyahIds.value,
      );
      final lineBreaksAvail = MushafPageRangeLayout.newlinesWouldCompact(
        page,
        selectedAyahIds.value,
      );

      if (!defaultsApplied.value) {
        defaultsApplied.value = true;
        included.value = defaultAyahShareIncludes(
          basmalahAvailable: basmalahAvail,
        );
        return null;
      }

      final next = Set.of(included.value);
      if (basmalahAvail) {
        next.add(AyahShareInclude.basmalah);
      } else {
        next.remove(AyahShareInclude.basmalah);
      }
      if (!lineBreaksAvail) {
        next.remove(AyahShareInclude.preserveLineBreaks);
      }
      if (next.length != included.value.length ||
          !next.containsAll(included.value)) {
        included.value = next;
      }
      return null;
    }, [page, selectedAyahIds.value.join(',')]);

    Widget buildShareCard() {
      final ids = selectedAyahIds.value;
      final preserveLineBreaks =
          included.value.contains(AyahShareInclude.preserveLineBreaks);
      return AyahShareCard(
        key: ValueKey('${ids.join(',')}-$preserveLineBreaks'),
        boundaryKey: boundaryKey,
        page: page!,
        ayahIds: ids,
        style: mushafStyle,
        showSurahHeader: included.value.contains(AyahShareInclude.surahHeader),
        showBasmalah: included.value.contains(AyahShareInclude.basmalah),
        showAppName: included.value.contains(AyahShareInclude.appName),
        preserveMushafLineBreaks: preserveLineBreaks,
        isDark: theme.isDark,
      );
    }

    Future<void> exportImage({required bool copyToClipboard}) async {
      if (isCapturing.value) return;
      isCapturing.value = true;
      try {
        final ids = selectedAyahIds.value;
        final loadedAyahs = await Future.wait(ids.map(controller.getAyah));
        await WidgetsBinding.instance.endOfFrame;
        final bytes = await captureWidgetToPng(boundaryKey);
        if (bytes == null) {
          if (context.mounted) {
            showFToast(
              context: context,
              title: Text(l10n.shareCouldNotCreateImage),
            );
          }
          return;
        }

        if (copyToClipboard) {
          final error = await copyPngToClipboard(bytes, l10n: l10n);
          if (context.mounted) {
            showFToast(
              context: context,
              title: Text(
                error ?? l10n.shareImageCopied,
              ),
            );
          }
          return;
        }

        final downloads = await getDownloadsDirectory();
        final directory = downloads ?? await getApplicationDocumentsDirectory();
        final startAyah = loadedAyahs.first;
        final endAyah = loadedAyahs.length == 1 ? startAyah : loadedAyahs.last;
        final startRef = filenameAyahReference(
          ayah: startAyah,
          controller: controller,
        );
        final endRef = filenameAyahReference(
          ayah: endAyah,
          controller: controller,
        );
        final safeReference = startRef == endRef
            ? startRef
            : '$startRef-$endRef';
        final file = File(
          p.join(directory.path, 'tawaq-$safeReference.png'),
        );
        await file.writeAsBytes(bytes);
        if (context.mounted) {
          showFToast(
            context: context,
            title: Text(l10n.shareImageSaved(file.path)),
          );
        }
      } on Object catch (error) {
        if (context.mounted) {
          showFToast(
            context: context,
            title: Text(l10n.shareExportFailed('$error')),
          );
        }
      } finally {
        isCapturing.value = false;
      }
    }

    final dialogSize = dialogConstraints(
      context,
      preferredWidth: isDesktopPlatform ? 920 : 680,
      preferredHeight: isDesktopPlatform ? 460 : 560,
      minWidth: 320,
    );

    /// Controls column width in the side-by-side desktop layout.
    const controlsWidth = 280.0;

    Widget buildPreviewPanel() {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colors.secondary.withAlpha(60),
          borderRadius: theme.radii.md,
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.sharePreview,
                style: theme.typography.sm.copyWith(
                  color: colors.mutedForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth,
                            ),
                            child: buildShareCard(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildControlsPanel() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AyahShareRangeSlider(
            key: ValueKey(
              'share-range-${ayah.page}-$selectedIndex-'
              '${pageAyahIds.length}',
            ),
            pageNumber: ayah.page,
            pageAyahIds: pageAyahIds,
            references: pageReferences,
            initialIndex: selectedIndex >= 0 ? selectedIndex : 0,
            onRangeChanged: (start, end) {
              selectedAyahIds.value = pageAyahIds.sublist(start, end + 1);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AyahShareIncludePanel(
            selected: included.value,
            basmalahAvailable: basmalahAvailable,
            lineBreaksToggleAvailable: lineBreaksToggleAvailable,
            onChanged: (options) => included.value = Set.of(options),
          ),
        ],
      );
    }

    Widget buildDialogBody() {
      if (pageSnapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: FCircularProgress.loader());
      }
      if (pageSnapshot.hasError) {
        return Center(
          child: Text(
            l10n.shareFailedToLoadPage('${pageSnapshot.error}'),
          ),
        );
      }

      return Directionality(
        textDirection: TextDirection.ltr,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Dialog width is below viewport `md` (768), so use container width
            // or desktop — not the page breakpoint — to pick side-by-side layout.
            final sideBySide =
                isDesktopPlatform ||
                constraints.maxWidth >= theme.breakpoints.sm;

            if (!sideBySide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildControlsPanel(),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(child: buildPreviewPanel()),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: buildPreviewPanel()),
                const SizedBox(width: AppSpacing.xl),
                SizedBox(
                  width: controlsWidth,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: buildControlsPanel(),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return FDialog(
      direction: .horizontal,
      title: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          Text(l10n.shareVerses),
          FButton.icon(
            onPress: () => Navigator.of(context).pop(),
            variant: .ghost,
            child: const Icon(FLucideIcons.x),
          ),
        ],
      ),
      constraints: dialogSize,
      body: buildDialogBody(),
      actions: [
        FButton(
          variant: .secondary,
          onPress: isCapturing.value
              ? null
              : () => unawaited(exportImage(copyToClipboard: false)),
          child: Text(l10n.shareSaveImage),
        ),
        FButton(
          onPress: isCapturing.value
              ? null
              : () => unawaited(exportImage(copyToClipboard: true)),
          child: Text(l10n.shareCopyImage),
        ),
      ],
    );
  }
}
