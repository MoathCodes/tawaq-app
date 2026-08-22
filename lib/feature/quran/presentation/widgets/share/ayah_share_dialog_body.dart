import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/share_card_dialog_layout.dart';
import 'package:tawaq/core/widgets/share_card_drag_surface.dart';
import 'package:tawaq/feature/quran/presentation/models/ayah_share_include.dart';
import 'package:tawaq/feature/quran/presentation/widgets/share/ayah_share_card.dart';
import 'package:tawaq/feature/quran/presentation/widgets/share/ayah_share_range_slider.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// View model passed to [AyahShareDialogBody].
class AyahShareDialogContent {
  /// Creates share dialog content state.
  const AyahShareDialogContent({
    required this.page,
    required this.pageAyahIds,
    required this.selectedAyahIds,
    required this.selectedIndex,
    required this.pageReferences,
    required this.options,
    required this.basmalahAvailable,
    required this.lineBreaksToggleAvailable,
    required this.boundaryKey,
    required this.mushafStyle,
    required this.isDark,
    required this.onRangeChanged,
    required this.onOptionsChanged,
  });

  final QuranPage page;
  final List<int> pageAyahIds;
  final List<int> selectedAyahIds;
  final int selectedIndex;
  final AyahSharePageReferences pageReferences;
  final AyahShareCardOptions options;
  final bool basmalahAvailable;
  final bool lineBreaksToggleAvailable;
  final GlobalKey boundaryKey;
  final MushafStyle mushafStyle;
  final bool isDark;
  final void Function(int start, int end) onRangeChanged;
  final ValueChanged<AyahShareCardOptions> onOptionsChanged;
}

/// Dialog body for configuring and previewing an ayah share image.
class AyahShareDialogBody extends StatelessWidget {
  /// Creates the share dialog body.
  const AyahShareDialogBody({required this.content, super.key});

  final AyahShareDialogContent content;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: ShareCardDialogLayout(
        preview: _PreviewPanel(
          content: content,
          colors: colors,
          theme: theme,
          l10n: l10n,
        ),
        settings: Align(
          alignment: Alignment.topCenter,
          child: _ControlsPanel(content: content, l10n: l10n),
        ),
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.content,
    required this.colors,
    required this.theme,
    required this.l10n,
  });

  final AyahShareDialogContent content;
  final FColors colors;
  final FThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
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
              style: theme.typography.body.sm.copyWith(
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
                          child: ShareCardDragSurface(
                            boundaryKey: content.boundaryKey,
                            child: AyahShareCard(
                              key: ValueKey(
                                '${content.selectedAyahIds.join(',')}-'
                                '${content.options.preserveMushafLineBreaks}',
                              ),
                              boundaryKey: content.boundaryKey,
                              page: content.page,
                              ayahIds: content.selectedAyahIds,
                              style: content.mushafStyle,
                              showSurahHeader: content.options.showSurahHeader,
                              showBasmalah: content.options.showBasmalah,
                              showAppName: content.options.showAppName,
                              preserveMushafLineBreaks:
                                  content.options.preserveMushafLineBreaks,
                              isDark: content.isDark,
                            ),
                          ),
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
}

class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel({
    required this.content,
    required this.l10n,
  });

  final AyahShareDialogContent content;
  final AppLocalizations l10n;

  void _handleIncludeChange(Set<AyahShareInclude> value) {
    var next = value;
    if (!content.basmalahAvailable) {
      next = next.difference({AyahShareInclude.basmalah});
    }
    if (!content.lineBreaksToggleAvailable) {
      next = next.difference({AyahShareInclude.preserveLineBreaks});
    }
    content.onOptionsChanged(
      content.options
          .copyWithIncludes(next)
          .constrained(
            basmalahAvailable: content.basmalahAvailable,
            lineBreaksToggleAvailable: content.lineBreaksToggleAvailable,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AyahShareRangeSlider(
          key: ValueKey(
            'share-range-${content.page.pageNumber}-${content.selectedIndex}-'
            '${content.pageAyahIds.length}',
          ),
          pageNumber: content.page.pageNumber,
          pageAyahIds: content.pageAyahIds,
          references: content.pageReferences,
          initialIndex: content.selectedIndex >= 0 ? content.selectedIndex : 0,
          onRangeChanged: content.onRangeChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        FSelectTileGroup<AyahShareInclude>(
          label: Text(l10n.shareIncludeInImage),
          control: .lifted(
            value: content.options.includes,
            onChange: _handleIncludeChange,
          ),
          children: [
            FSelectTile(
              value: AyahShareInclude.surahHeader,
              title: Text(l10n.shareSurahHeader),
            ),
            if (content.basmalahAvailable)
              FSelectTile(
                value: AyahShareInclude.basmalah,
                title: Text(l10n.shareBasmalah),
              ),
            if (content.lineBreaksToggleAvailable)
              FSelectTile(
                value: AyahShareInclude.preserveLineBreaks,
                title: Text(l10n.sharePreserveLineBreaks),
              ),
            FSelectTile(
              value: AyahShareInclude.appName,
              title: Text(l10n.shareAppName),
            ),
          ],
        ),
      ],
    );
  }
}
