import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:forui_hooks/forui_hooks.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';
import 'package:hasanat/theme/theme.dart';

/// A study companion panel for the Quran screen.
class StudyPanel extends HookWidget {
  /// Creates a study panel.
  const StudyPanel({
    super.key,
    this.selectedAyahId,
    this.surahName,
    this.ayahNumber,
  });

  /// The currently selected ayah ID.
  final int? selectedAyahId;

  /// The name of the current surah.
  final String? surahName;

  /// The current ayah number within the surah.
  final int? ayahNumber;

  @override
  Widget build(BuildContext context) {
    final accordionController = useFAccordionController();
    final notesController = useTextEditingController();
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final typography = theme.typography;

    return HoverCard(
      padding: .zero,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          _Header(
            colors: colors,
            typography: typography,
            surahName: surahName,
            ayahNumber: ayahNumber,
            hasSelection: selectedAyahId != null,
          ),
          const FDivider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const .all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: .stretch,
                children: [
                  _ContentAccordion(
                    colors: colors,
                    typography: typography,
                    controller: accordionController,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _NotesSection(
                    colors: colors,
                    typography: typography,
                    controller: notesController,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.colors,
    required this.typography,
    this.surahName,
    this.ayahNumber,
    required this.hasSelection,
  });
  final FColors colors;
  final FTypography typography;
  final String? surahName;
  final int? ayahNumber;
  final bool hasSelection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(FIcons.bookOpen, size: 20, color: colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  'Study Mode',
                  style: typography.base.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
                if (hasSelection) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${surahName ?? 'Al-Fatihah'} • Ayah ${ayahNumber ?? 1}',
                    style: typography.sm.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ...[FIcons.search, FIcons.ellipsisVertical].map(
            (icon) => FButton.icon(
              onPress: () {},
              style: FButtonStyle.ghost(),
              child: Icon(icon, size: 16, color: colors.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentAccordion extends StatelessWidget {
  const _ContentAccordion({
    required this.colors,
    required this.typography,
    required this.controller,
  });
  final FColors colors;
  final FTypography typography;
  final FAccordionController controller;

  Widget _sectionTitle(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 16, color: colors.primary),
      const SizedBox(width: AppSpacing.sm),
      Text(text),
    ],
  );

  Widget _labeledContent(
    String label,
    String badge,
    String content, {
    bool italic = false,
  }) => Padding(
    padding: const .symmetric(vertical: AppSpacing.md),
    child: Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          children: [
            Text(
              '$label:',
              style: typography.sm.copyWith(color: colors.mutedForeground),
            ),
            const SizedBox(width: AppSpacing.sm),
            FBadge(style: FBadgeStyle.secondary(), child: Text(badge)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          content,
          style: typography.sm.copyWith(
            color: colors.foreground,
            height: 1.6,
            fontStyle: italic ? FontStyle.italic : null,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return FAccordion(
      control: FAccordionControl.managed(controller: controller),
      style: (style) => style.copyWith(
        dividerStyle: FDividerStyle(color: colors.border, padding: .zero).call,
      ),
      children: [
        FAccordionItem(
          initiallyExpanded: true,
          title: _sectionTitle(FIcons.messageSquare, 'Tafsir'),
          child: _labeledContent(
            'Source',
            'Ibn Kathir',
            'This verse emphasizes patience and gratitude. It serves as a reminder for believers during times of difficulty. The scholars have noted that this ayah connects to the broader theme of steadfastness in faith, encouraging Muslims to maintain their trust in Allah through all circumstances.',
          ),
        ),
        FAccordionItem(
          title: _sectionTitle(FIcons.languages, 'Translation'),
          child: _labeledContent(
            'Language',
            'English',
            '"In the name of Allah, the Most Gracious, the Most Merciful."',
            italic: true,
          ),
        ),
        FAccordionItem(
          title: _sectionTitle(FIcons.info, 'Word Analysis'),
          child: Padding(
            padding: const .symmetric(vertical: AppSpacing.md),
            child: Text(
              'Tap on a word in the Mushaf to see its analysis.',
              style: typography.sm.copyWith(
                color: colors.mutedForeground,
                height: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({
    required this.colors,
    required this.typography,
    required this.controller,
  });
  final FColors colors;
  final FTypography typography;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          children: [
            Icon(FIcons.penLine, size: 16, color: colors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Add a reflection...',
              style: typography.sm.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        FTextField(
          control: FTextFieldControl.managed(controller: controller),
          minLines: 3,
          maxLines: 5,
          hint: 'Write your thoughts about this verse...',
          style: (style) =>
              style.copyWith(contentPadding: const .all(AppSpacing.md)),
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerRight,
          child: FButton(
            onPress: () {},
            style: FButtonStyle.secondary(),
            child: const Text('Save Note'),
          ),
        ),
      ],
    );
  }
}
