import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/feature/quran/domain/models/quran_text_scale.dart';
import 'package:tawaq/feature/quran/presentation/extensions/ayah_reference_formatter.dart';
import 'package:tawaq/feature/quran/presentation/models/ayah_share_include.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_mushaf_style.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/share/ayah_share_dialog_body.dart';
import 'package:tawaq/feature/quran/presentation/widgets/share/ayah_share_export.dart';
import 'package:tawaq/feature/quran/presentation/widgets/share/ayah_share_range_slider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
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
  required Ayah ayah,
}) {
  return showFDialog<void>(
    context: context,
    builder: (context, style, animation) => AyahShareDialog(
      ayah: ayah,
      style: style,
      animation: animation,
    ),
  );
}

/// Dialog for configuring and exporting a verse range as a shareable image.
class AyahShareDialog extends HookConsumerWidget {
  /// Creates the share dialog.
  const AyahShareDialog({
    required this.ayah,
    required this.style,
    this.animation,
    super.key,
  });

  final Ayah ayah;

  /// Resolved dialog style from [showFDialog].
  final FDialogStyle style;

  /// Route entrance/exit animation from [showFDialog].
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(quranMushafControllerProvider);
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

    final options = useState(
      AyahShareCardOptions.defaults(basmalahAvailable: false),
    );
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
    final defaultsApplied = useRef(false);

    final basmalahAvailable =
        page != null &&
        MushafPageRangeLayout.basmalahPossible(page, selectedAyahIds.value);
    final lineBreaksToggleAvailable =
        page != null &&
        MushafPageRangeLayout.newlinesWouldCompact(
          page,
          selectedAyahIds.value,
        );

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
        options.value = AyahShareCardOptions.defaults(
          basmalahAvailable: basmalahAvail,
        );
        return null;
      }

      options.value = options.value.constrained(
        basmalahAvailable: basmalahAvail,
        lineBreaksToggleAvailable: lineBreaksAvail,
      );
      return null;
    }, [page, selectedAyahIds.value.join(',')]);

    Future<void> exportImage({required bool copyToClipboard}) async {
      if (isCapturing.value) return;
      isCapturing.value = true;
      try {
        await exportAyahShareImage(
          context: context,
          boundaryKey: boundaryKey,
          controller: controller,
          ayahIds: selectedAyahIds.value,
          l10n: l10n,
          primaryColor: colors.primary,
          copyToClipboard: copyToClipboard,
        );
      } finally {
        isCapturing.value = false;
      }
    }

    final dialogSize = dialogConstraints(
      context,
      preferredWidth: isDesktopPlatform ? 920 : 680,
      preferredHeight: isDesktopPlatform ? 500 : 560,
      minWidth: 320,
    );

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

      return AyahShareDialogBody(
        content: AyahShareDialogContent(
          page: page!,
          pageAyahIds: pageAyahIds,
          selectedAyahIds: selectedAyahIds.value,
          selectedIndex: selectedIndex,
          pageReferences: pageReferences,
          options: options.value,
          basmalahAvailable: basmalahAvailable,
          lineBreaksToggleAvailable: lineBreaksToggleAvailable,
          boundaryKey: boundaryKey,
          mushafStyle: mushafStyle,
          isDark: theme.isDark,
          onRangeChanged: (start, end) {
            selectedAyahIds.value = pageAyahIds.sublist(start, end + 1);
          },
          onOptionsChanged: (next) => options.value = next,
        ),
      );
    }

    return FDialog(
      style: style,
      animation: animation,
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
