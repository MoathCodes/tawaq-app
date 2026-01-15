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
      } catch (e) {
        sharhError.value = 'فشل تحميل الشرح: $e';
      }
      isLoadingSharh.value = false;
    }

    final theme = FTheme.of(context);
    final colors = theme.colors;

    return HoverCard(
      padding: const .all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: 16,
        children: [
          _HadithText(hadith: hadith, theme: theme, isHTML: isHTML),
          _InfoRow(
            icon: FIcons.user,
            label: 'الراوي',
            value: hadith.rawi,
            theme: theme,
          ),
          _BookInfo(hadith: hadith, theme: theme, colors: colors),
          _GradeSection(hadith: hadith, theme: theme, colors: colors),
          if (hadith.explainGrade != null)
            _StyledSection(
              colors: colors,
              theme: theme,
              icon: FIcons.info,
              title: 'شرح الحكم',
              child: Text(hadith.explainGrade!, style: theme.typography.sm),
            ),
          if (hadith.takhrij?.isNotEmpty ?? false)
            _StyledSection(
              colors: colors,
              theme: theme,
              icon: FIcons.library,
              title: 'التخريج',
              child: Text(hadith.takhrij!, style: theme.typography.sm),
            ),
          if (hadith.hasSharhMetadata && hadith.sharhMetadata != null)
            _SharhSection(
              hadith: hadith,
              theme: theme,
              colors: colors,
              loadedSharh: loadedSharh.value,
              isLoading: isLoadingSharh.value,
              error: sharhError.value,
              onLoad: loadSharh,
            ),
          if (hadith.hasSimilarHadith ||
              hadith.hasAlternateHadithSahih ||
              hadith.hasUsulHadith)
            _RelatedLinks(hadith: hadith, theme: theme, colors: colors),
        ],
      ),
    );
  }
}

// =============================================================================
// Reusable styled section container
// =============================================================================

class _StyledSection extends StatelessWidget {
  const _StyledSection({
    required this.colors,
    required this.theme,
    required this.icon,
    required this.title,
    required this.child,
    this.backgroundColor,
  });
  final FColors colors;
  final FThemeData theme;
  final IconData icon;
  final String title;
  final Widget child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.secondary.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: theme.typography.sm.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

class _HadithText extends StatelessWidget {
  const _HadithText({
    required this.hadith,
    required this.theme,
    required this.isHTML,
  });
  final DetailedHadith hadith;
  final FThemeData theme;
  final bool isHTML;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colors.secondary.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: isHTML
          ? Text(hadith.hadith)
          : SelectableText(
              hadith.hadith,
              style: theme.typography.xl2.copyWith(
                height: 1.8,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });
  final IconData icon;
  final String label;
  final String value;
  final FThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
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
}

class _BookInfo extends StatelessWidget {
  const _BookInfo({
    required this.hadith,
    required this.theme,
    required this.colors,
  });
  final DetailedHadith hadith;
  final FThemeData theme;
  final FColors colors;

  @override
  Widget build(BuildContext context) {
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
}

class _GradeSection extends StatelessWidget {
  const _GradeSection({
    required this.hadith,
    required this.theme,
    required this.colors,
  });
  final DetailedHadith hadith;
  final FThemeData theme;
  final FColors colors;

  Color _gradeColor() {
    final g = hadith.grade.toLowerCase();
    if (g.contains('صحيح')) return Colors.green;
    if (g.contains('حسن')) return Colors.blue;
    if (g.contains('ضعيف')) return Colors.orange;
    if (g.contains('موضوع') || g.contains('منكر')) return Colors.red;
    return colors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final gradeColor = _gradeColor();
    return Container(
      padding: const .all(AppSpacing.md),
      decoration: BoxDecoration(
        color: gradeColor.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: gradeColor.withAlpha(40)),
      ),
      child: Row(
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
            padding: const .symmetric(horizontal: 12, vertical: 6),
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
    );
  }
}

class _SharhSection extends StatelessWidget {
  const _SharhSection({
    required this.hadith,
    required this.theme,
    required this.colors,
    required this.loadedSharh,
    required this.isLoading,
    required this.error,
    required this.onLoad,
  });
  final DetailedHadith hadith;
  final FThemeData theme;
  final FColors colors;
  final String? loadedSharh;
  final bool isLoading;
  final String? error;
  final Future<void> Function(String) onLoad;

  @override
  Widget build(BuildContext context) {
    final sharh = hadith.sharhMetadata!;
    Widget content;

    if (loadedSharh != null) {
      content = SelectableText(
        loadedSharh!,
        style: theme.typography.sm.copyWith(height: 1.6),
      );
    } else if (isLoading) {
      content = const Center(
        child: Padding(
          padding: .all(AppSpacing.lg),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (error != null) {
      content = Column(
        children: [
          Text(error!, style: theme.typography.sm.copyWith(color: Colors.red)),
          const SizedBox(height: AppSpacing.sm),
          FButton(
            onPress: () => onLoad(sharh.id),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      );
    } else if (sharh.sharh != null) {
      content = SelectableText(
        sharh.sharh!,
        style: theme.typography.sm.copyWith(height: 1.6),
      );
    } else {
      content = Center(
        child: FButton(
          onPress: () => onLoad(sharh.id),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(FIcons.download, size: 16),
              const SizedBox(width: AppSpacing.sm),
              Text('تحميل الشرح', style: theme.typography.sm),
            ],
          ),
        ),
      );
    }

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
          content,
        ],
      ),
    );
  }
}

class _RelatedLinks extends StatelessWidget {
  const _RelatedLinks({
    required this.hadith,
    required this.theme,
    required this.colors,
  });
  final DetailedHadith hadith;
  final FThemeData theme;
  final FColors colors;

  Widget _chip(IconData icon, String label) => Container(
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
        Text(label, style: theme.typography.sm.copyWith(color: colors.primary)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
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
          if (hadith.hasSimilarHadith) _chip(FIcons.copy, 'أحاديث مشابهة'),
          if (hadith.hasAlternateHadithSahih)
            _chip(FIcons.check, 'روايات صحيحة بديلة'),
          if (hadith.hasUsulHadith) _chip(FIcons.bookOpen, 'الأصول'),
        ],
      ),
    );
  }
}
