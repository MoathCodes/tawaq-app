import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/hooks/hooks.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';
import 'package:hasanat/theme/theme.dart';

/// A study companion panel for the Quran screen.
///
/// Displays Tafsir, translation, and notes for the selected ayah.
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
    final colors = FTheme.of(context).colors;
    final typography = FTheme.of(context).typography;

    return StaticCard(
      padding: .zero,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          // Header
          _buildHeader(colors, typography),
          const FDivider(),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const .all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: .stretch,
                children: [
                  // Tafsir & Translation Accordion
                  _buildAccordion(colors, typography, accordionController),
                  const SizedBox(height: AppSpacing.xl),
                  // Notes Section
                  _buildNotesSection(colors, typography, notesController),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(FColors colors, FTypography typography) {
    final hasSelection = selectedAyahId != null;

    return Container(
      padding: const .all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(
            FIcons.bookOpen,
            size: 20,
            color: colors.primary,
          ),
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
          FButton.icon(
            onPress: () {},
            style: FButtonStyle.ghost(),
            child: Icon(
              FIcons.search,
              size: 16,
              color: colors.mutedForeground,
            ),
          ),
          FButton.icon(
            onPress: () {},
            style: FButtonStyle.ghost(),
            child: Icon(
              FIcons.ellipsisVertical,
              size: 16,
              color: colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccordion(
    FColors colors,
    FTypography typography,
    FAccordionController accordionController,
  ) {
    return FAccordion(
      control: FAccordionControl.managed(controller: accordionController),
      style: (style) => style.copyWith(
        dividerStyle: FDividerStyle(
          color: colors.border,
          padding: .zero,
        ).call,
      ),
      children: [
        FAccordionItem(
          initiallyExpanded: true,
          title: Row(
            children: [
              Icon(
                FIcons.messageSquare,
                size: 16,
                color: colors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text('Tafsir'),
            ],
          ),
          child: _buildTafsirContent(colors, typography),
        ),
        FAccordionItem(
          title: Row(
            children: [
              Icon(
                FIcons.languages,
                size: 16,
                color: colors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text('Translation'),
            ],
          ),
          child: _buildTranslationContent(colors, typography),
        ),
        FAccordionItem(
          title: Row(
            children: [
              Icon(
                FIcons.info,
                size: 16,
                color: colors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text('Word Analysis'),
            ],
          ),
          child: _buildWordAnalysisContent(colors, typography),
        ),
      ],
    );
  }

  Widget _buildTafsirContent(FColors colors, FTypography typography) {
    return Padding(
      padding: const .symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          // Tafsir source selector
          Row(
            children: [
              Text(
                'Source:',
                style: typography.sm.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FBadge(
                style: FBadgeStyle.secondary(),
                child: const Text('Ibn Kathir'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Tafsir text (placeholder)
          Text(
            'This verse emphasizes patience and gratitude. It serves as a '
            'reminder for believers during times of difficulty. The scholars '
            'have noted that this ayah connects to the broader theme of '
            'steadfastness in faith, encouraging Muslims to maintain their '
            'trust in Allah through all circumstances.',
            style: typography.sm.copyWith(
              color: colors.foreground,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationContent(FColors colors, FTypography typography) {
    return Padding(
      padding: const .symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Text(
                'Language:',
                style: typography.sm.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FBadge(
                style: FBadgeStyle.secondary(),
                child: const Text('English'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '"In the name of Allah, the Most Gracious, the Most Merciful."',
            style: typography.sm.copyWith(
              color: colors.foreground,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordAnalysisContent(
    FColors colors,
    FTypography typography,
  ) {
    return Padding(
      padding: const .symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            'Tap on a word in the Mushaf to see its analysis.',
            style: typography.sm.copyWith(
              color: colors.mutedForeground,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(
    FColors colors,
    FTypography typography,
    TextEditingController notesController,
  ) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          children: [
            Icon(
              FIcons.penLine,
              size: 16,
              color: colors.primary,
            ),
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
          control: FTextFieldControl.managed(controller: notesController),
          minLines: 3,
          maxLines: 5,
          hint: 'Write your thoughts about this verse...',
          style: (style) => style.copyWith(
            contentPadding: const .all(AppSpacing.md),
          ),
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
