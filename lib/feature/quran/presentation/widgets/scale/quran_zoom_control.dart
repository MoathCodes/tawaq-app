import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_ui_models.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/theme/theme.dart';

/// Continuous mushaf zoom slider (fit-page → fill-width).
///
/// Mirrors the app's volume slider pattern: local state follows the persisted
/// value, live preview while dragging, commit on release.
class QuranZoomControl extends HookConsumerWidget {
  /// Creates a [QuranZoomControl].
  const QuranZoomControl({
    this.showHeader = false,
    super.key,
  });

  /// When true, renders a title row with the live percentage and reset.
  ///
  /// Used by the header popover; Settings already has its own group title.
  final bool showHeader;

  static const double _span = kMushafZoomMax - kMushafZoomMin;
  static const double _fitMark = (kMushafZoomFitPage - kMushafZoomMin) / _span;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final persistedZoom = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.mushafZoom ?? kMushafZoomDefault,
      ),
    );
    final ready = ref.watch(
      quranScreenSettingsProvider.select((s) => s.hasValue),
    );

    final zoomState = useState(persistedZoom);
    useEffect(() {
      zoomState.value = persistedZoom;
      return null;
    }, [persistedZoom]);

    final normalized = ((zoomState.value - kMushafZoomMin) / _span).clamp(
      0.0,
      1.0,
    );
    final pastFit = zoomState.value > kMushafZoomFitPage + 0.001;
    final notifier = ref.read(quranScreenSettingsProvider.notifier);

    void preview(double zoom) {
      zoomState.value = clampMushafZoom(zoom);
    }

    void commit(double zoom) {
      notifier.setMushafZoom(zoom);
    }

    void resetToFit() {
      preview(kMushafZoomFitPage);
      commit(kMushafZoomFitPage);
    }

    final percentLabel = Text(
      l10n.quranZoomPercent(mushafZoomPercent(zoomState.value)),
      style: theme.typography.body.sm.copyWith(
        fontWeight: FontWeight.w600,
        color: colors.mutedForeground,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );

    final resetButton = FTooltip(
      tipBuilder: (_, _) => Text(l10n.quranZoomReset),
      child: QuranSemantics.labeledControl(
        name: l10n.quranZoomReset,
        button: true,
        excludeChild: true,
        child: FButton.icon(
          semanticsTooltip: l10n.quranZoomReset,
          variant: .ghost,
          onPress: ready && zoomState.value != kMushafZoomFitPage
              ? resetToFit
              : null,
          child: QuranSemantics.decorative(
            const Icon(FLucideIcons.rotateCcw, size: 16),
          ),
        ),
      ),
    );

    final slider = FSlider(
      enabled: ready,
      control: FSliderControl.liftedContinuous(
        value: FSliderValue(max: normalized),
        onChange: (value) {
          preview(kMushafZoomMin + value.max * _span);
        },
      ),
      onEnd: (value) {
        commit(kMushafZoomMin + value.max * _span);
      },
      marks: [
        // Min is a tick only — the live % in the header is the reading value.
        const FSliderMark.mark(value: 0),
        FSliderMark.mark(
          value: _fitMark,
          label: Text(
            l10n.quranZoomFitPage,
            style: theme.typography.body.xs.copyWith(
              color: colors.mutedForeground,
            ),
          ),
        ),
        FSliderMark.mark(
          value: 1,
          label: Text(
            l10n.quranZoomFillWidth,
            style: theme.typography.body.xs.copyWith(
              color: colors.mutedForeground,
            ),
          ),
        ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.quranTextSize,
                  style: theme.typography.body.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              percentLabel,
              resetButton,
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              percentLabel,
              resetButton,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: slider,
        ),
        AnimatedSize(
          duration: theme.durations.fast,
          alignment: Alignment.topCenter,
          child: pastFit
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(
                    l10n.quranZoomFillWidthHint,
                    style: theme.typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
