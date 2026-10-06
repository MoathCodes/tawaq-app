import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_ui_models.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/scale/quran_zoom_control.dart';
import 'package:tawaq/feature/quran/presentation/widgets/ayah_selection_actions.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/quran_search_field.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/study_panel.dart';
import 'package:tawaq/theme/theme.dart';

/// Reading navigation with secondary controls in a bounded surface.
class QuranHeaderWidget extends ConsumerWidget {
  const new({
    this.onStudy,
    this.onNotes,
    this.studyOpen = false,
    this.studyInPopover = false,
    this.onStudyDismiss,
    super.key,
  });
  final bool studyOpen;
  final bool studyInPopover;
  final VoidCallback? onStudyDismiss;
  final VoidCallback? onStudy;
  final VoidCallback? onNotes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: NonSelectable(
        child: Row(
          spacing: AppSpacing.sm,
          children: [
            const Expanded(child: QuranSearchField()),
            if (ref.watch(quranSelectedAyahIdProvider) != null)
              FPopover(
                semanticsLabel: l10n.ayahActions,
                popoverBuilder: (context, _) => ConstrainedBox(
                  constraints: dialogConstraints(context, preferredWidth: 440),
                  child: const Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: AyahSelectionActionsBar(),
                  ),
                ),
                builder: (context, controller, _) => _HeaderAction(
                  label: l10n.ayahActions,
                  icon: FLucideIcons.ellipsis,
                  onPress: controller.toggle,
                ),
              ),
            if (studyInPopover)
              FPopover(
                // The reader stays interactive while choosing an ayah.
                // Close through the trigger, Back to reading, or Escape.
                hideRegion: .none,
                control: FPopoverControl.lifted(
                  shown: studyOpen,
                  onChange: (shown) {
                    if (!shown) onStudyDismiss?.call();
                  },
                ),
                semanticsLabel: l10n.studyMode,
                popoverBuilder: (context, controller) => Consumer(
                  builder: (context, ref, _) {
                    final hasSelection =
                        ref.watch(quranSelectedAyahIdProvider) != null;
                    final bounds = dialogConstraints(
                      context,
                      preferredWidth: hasSelection ? 620 : 320,
                    );
                    final panel = StudyPanel(onBackToReading: controller.hide);
                    return SizedBox(
                      width: bounds.maxWidth,
                      height: hasSelection ? bounds.maxHeight : null,
                      child: panel,
                    );
                  },
                ),
                child: _HeaderAction(
                  label: studyOpen ? l10n.collapsePanel : l10n.studyMode,
                  selected: studyOpen,
                  icon: FLucideIcons.bookOpen,
                  onPress: onStudy,
                ),
              )
            else
              _HeaderAction(
                label: studyOpen ? l10n.collapsePanel : l10n.studyMode,
                selected: studyOpen,
                icon: FLucideIcons.bookOpen,
                onPress: onStudy,
              ),
            _HeaderAction(
              label: l10n.studyTabMyReflections,
              icon: FLucideIcons.notebookPen,
              onPress: onNotes,
            ),
            FPopover(
              semanticsLabel: l10n.quranNavigation,
              popoverBuilder: (context, _) => ConstrainedBox(
                constraints: dialogConstraints(context, preferredWidth: 380),
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: _DisplayControls(),
                ),
              ),
              builder: (context, controller, _) => _HeaderAction(
                label: l10n.quranNavigation,
                icon: FLucideIcons.slidersHorizontal,
                onPress: controller.toggle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const new({
    required this.label,
    required this.icon,
    required this.onPress,
    this.selected = false,
  });
  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) => FTooltip(
    tipBuilder: (_, _) => Text(label),
    child: Semantics(
      label: label,
      selected: selected,
      child: FButton.icon(
        variant: selected ? .secondary : .ghost,
        onPress: onPress,
        child: Icon(icon, size: 18),
      ),
    ),
  );
}

class _DisplayControls extends ConsumerWidget {
  const new();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout =
        ref.watch(quranScreenSettingsProvider).value?.layout ??
        QuranReadingLayout.studyMode;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        Text(
          context.l10n.quranNavigation,
          style: context.theme.typography.body.md.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        _LayoutSegment(
          layout: layout,
          showLabels: true,
          onLayoutChanged: (index) => ref
              .read(quranScreenSettingsProvider.notifier)
              .setLayout(QuranReadingLayout.values[index]),
        ),
        const QuranZoomControl(showHeader: true),
      ],
    );
  }
}

class _LayoutSegment extends StatelessWidget {
  const new({
    required this.layout,
    required this.showLabels,
    required this.onLayoutChanged,
  });

  final QuranReadingLayout layout;
  final bool showLabels;
  final ValueChanged<int> onLayoutChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // The mushaf itself is a sibling of the header, so the entries carry no
    // content; only the bar is rendered. `IntrinsicWidth` sizes the bar to
    // twice its widest label, since the surrounding `Row` offers unbounded
    // width and the tabs divide whatever they are given.
    return IntrinsicWidth(
      child: FTabs(
        style: context.theme.tabs.compact,
        control: FTabControl.lifted(
          index: layout.index,
          onChange: onLayoutChanged,
        ),
        children: [
          for (final mode in QuranReadingLayout.values)
            FTabEntry(
              label: _LayoutTabLabel(
                mode: mode,
                label: mode.getLocaleName(l10n),
                selected: mode == layout,
                showLabel: showLabels,
              ),
              child: const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

class _LayoutTabLabel extends StatelessWidget {
  const new({
    required this.mode,
    required this.label,
    required this.selected,
    required this.showLabel,
  });

  final QuranReadingLayout mode;
  final String label;
  final bool selected;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final icon = Icon(
      mode.icon,
      size: 16,
      color: selected ? colors.primary : colors.mutedForeground,
    );

    if (!showLabel) {
      return FTooltip(
        tipBuilder: (_, _) => Text(label, semanticsLabel: label),
        child: icon,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs,
      children: [
        icon,
        Flexible(child: Text(label, maxLines: 2, textAlign: TextAlign.center)),
      ],
    );
  }
}
