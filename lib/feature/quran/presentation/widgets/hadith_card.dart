import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';
import 'package:hasanat/theme/theme.dart';

/// A card widget that displays a Hadith.
class HadithCard extends HookWidget {
  /// Creates a [HadithCard] instance.
  const HadithCard({
    required this.hadith,
    this.isHTML = false,
    this.onTap,
    super.key,
  });

  /// The Hadith to display.
  final DetailedHadith hadith;

  /// Whether the Hadith content is in HTML format.
  final bool isHTML;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final client = useMemoized(DorarClient.new);
    final loadedSharh = useState<String?>(null);
    final isLoadingSharh = useState(false);
    final sharhError = useState<String?>(null);

    Future<void> loadSharh(String sharhId) async {
      isLoadingSharh.value = true;
      sharhError.value = null;

      try {
        final response = await client.sharh.getById(sharhId);
        loadedSharh.value = response.sharhText;
        isLoadingSharh.value = false;
      } catch (e) {
        sharhError.value = 'فشل تحميل الشرح: $e';
        isLoadingSharh.value = false;
      }
    }

    final theme = FTheme.of(context);
    final colors = theme.colors;

    return StaticCard(
      padding: const .all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: 16,
        children: [
          if (isHTML) _buildHadithHTML(theme),
          // Hadith Text
          if (!isHTML) _buildHadithText(theme),

          // Narrator
          _buildInfoRow(
            icon: FIcons.user,
            label: 'الراوي',
            value: hadith.rawi,
            colors: colors,
            theme: theme,
          ),

          // Book and Reference
          _buildBookInfo(theme, colors),

          // Scholar (Mohdith) and Grade
          _buildGradeSection(theme, colors),

          // Additional Info
          if (hadith.explainGrade != null) _buildExplanation(theme, colors),

          // Takhrij
          if (hadith.takhrij != null && hadith.takhrij!.isNotEmpty)
            _buildTakhrij(theme, colors),

          // Sharh (if available)
          if (hadith.hasSharhMetadata && hadith.sharhMetadata != null)
            _buildSharhSection(
              theme,
              colors,
              loadedSharh: loadedSharh.value,
              isLoadingSharh: isLoadingSharh.value,
              sharhError: sharhError.value,
              onLoadSharh: loadSharh,
            ),

          // Related Hadiths Links
          if (hadith.hasSimilarHadith ||
              hadith.hasAlternateHadithSahih ||
              hadith.hasUsulHadith)
            _buildRelatedLinks(theme, colors),
        ],
      ),
    );
  }

  Widget _buildBookInfo(FThemeData theme, FColors colors) {
    return Container(
      padding: const .all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(FIcons.book, size: 20, color: colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  'المصدر',
                  style: theme.typography.sm.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  hadith.book,
                  style: theme.typography.base.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const .symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              hadith.numberOrPage,
              style: theme.typography.sm.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanation(FThemeData theme, FColors colors) {
    return Container(
      padding: const .all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.secondary.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Icon(FIcons.info, size: 16, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'شرح الحكم',
                style: theme.typography.sm.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(hadith.explainGrade!, style: theme.typography.sm),
        ],
      ),
    );
  }

  Widget _buildGradeSection(FThemeData theme, FColors colors) {
    final gradeColor = _getGradeColor(hadith.grade, colors);

    return Container(
      padding: const .all(AppSpacing.md),
      decoration: BoxDecoration(
        color: gradeColor.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: gradeColor.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              Icon(FIcons.check, size: 20, color: gradeColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      'المحدث',
                      style: theme.typography.sm.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      hadith.mohdith,
                      style: theme.typography.base.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const .symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: gradeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hadith.grade,
                  style: theme.typography.sm.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHadithHTML(FThemeData theme) {
    return Container(
      padding: const .all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colors.secondary.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(hadith.hadith),
    );
  }

  Widget _buildHadithText(FThemeData theme) {
    return Container(
      padding: const .all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colors.secondary.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SelectableText(
        hadith.hadith,
        style: theme.typography.xl2.copyWith(
          height: 1.8,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required FColors colors,
    required FThemeData theme,
  }) {
    return Row(
      children: [
        Container(
          padding: const .all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: colors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: colors.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                label,
                style: theme.typography.sm.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: theme.typography.base.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLinkChip({
    required IconData icon,
    required String label,
    required FColors colors,
    required FThemeData theme,
  }) {
    return Container(
      padding: const .symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: theme.typography.sm.copyWith(color: colors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedLinks(FThemeData theme, FColors colors) {
    return Container(
      padding: const .all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: .start,
        spacing: 8,
        children: [
          Text(
            'روابط ذات صلة',
            style: theme.typography.sm.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (hadith.hasSimilarHadith)
            _buildLinkChip(
              icon: FIcons.copy,
              label: 'أحاديث مشابهة',
              colors: colors,
              theme: theme,
            ),
          if (hadith.hasAlternateHadithSahih)
            _buildLinkChip(
              icon: FIcons.check,
              label: 'روايات صحيحة بديلة',
              colors: colors,
              theme: theme,
            ),
          if (hadith.hasUsulHadith)
            _buildLinkChip(
              icon: FIcons.bookOpen,
              label: 'الأصول',
              colors: colors,
              theme: theme,
            ),
        ],
      ),
    );
  }

  Widget _buildSharhSection(
    FThemeData theme,
    FColors colors, {
    required String? loadedSharh,
    required bool isLoadingSharh,
    required String? sharhError,
    required Future<void> Function(String) onLoadSharh,
  }) {
    final sharh = hadith.sharhMetadata!;

    return Container(
      padding: const .all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.primary.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Icon(FIcons.bookOpen, size: 16, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'الشرح',
                style: theme.typography.sm.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (loadedSharh != null) ...[
            SelectableText(
              loadedSharh,
              style: theme.typography.sm.copyWith(height: 1.6),
            ),
          ] else if (isLoadingSharh) ...[
            const Center(
              child: Padding(
                padding: .all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              ),
            ),
          ] else if (sharhError != null) ...[
            Text(
              sharhError,
              style: theme.typography.sm.copyWith(color: Colors.red),
            ),
            const SizedBox(height: AppSpacing.sm),
            FButton(
              onPress: () => onLoadSharh(sharh.id),
              child: const Text('إعادة المحاولة'),
            ),
          ] else if (sharh.sharh != null) ...[
            SelectableText(
              sharh.sharh!,
              style: theme.typography.sm.copyWith(height: 1.6),
            ),
          ] else ...[
            Center(
              child: FButton(
                onPress: () => onLoadSharh(sharh.id),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(FIcons.download, size: 16),
                    const SizedBox(width: AppSpacing.sm),
                    Text('تحميل الشرح', style: theme.typography.sm),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTakhrij(FThemeData theme, FColors colors) {
    return Container(
      padding: const .all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.secondary.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Icon(FIcons.library, size: 16, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'التخريج',
                style: theme.typography.sm.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(hadith.takhrij!, style: theme.typography.sm),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade, FColors colors) {
    final gradeLower = grade.toLowerCase();
    if (gradeLower.contains('صحيح')) {
      return Colors.green;
    } else if (gradeLower.contains('حسن')) {
      return Colors.blue;
    } else if (gradeLower.contains('ضعيف')) {
      return Colors.orange;
    } else if (gradeLower.contains('موضوع') || gradeLower.contains('منكر')) {
      return Colors.red;
    }
    return colors.primary;
  }
}
