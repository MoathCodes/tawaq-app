import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';

class HadithCard extends StatefulWidget {
  final DetailedHadith hadith;
  final bool isHTML;
  final VoidCallback? onTap;

  const HadithCard({
    required this.hadith,
    this.isHTML = false,
    this.onTap,
    super.key,
  });

  @override
  State<HadithCard> createState() => _HadithCardState();
}

class _HadithCardState extends State<HadithCard> {
  final DorarClient _client = DorarClient();
  String? _loadedSharh;
  bool _isLoadingSharh = false;
  String? _sharhError;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final colors = theme.colors;

    return StaticCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          if (widget.isHTML) _buildHadithHTML(theme),
          // Hadith Text
          if (!widget.isHTML) _buildHadithText(theme),

          // Narrator
          _buildInfoRow(
            icon: FIcons.user,
            label: 'الراوي',
            value: widget.hadith.rawi,
            colors: colors,
            theme: theme,
          ),

          // Book and Reference
          _buildBookInfo(theme, colors),

          // Scholar (Mohdith) and Grade
          _buildGradeSection(theme, colors),

          // Additional Info
          if (widget.hadith.explainGrade != null)
            _buildExplanation(theme, colors),

          // Takhrij
          if (widget.hadith.takhrij != null &&
              widget.hadith.takhrij!.isNotEmpty)
            _buildTakhrij(theme, colors),

          // Sharh (if available)
          if (widget.hadith.hasSharhMetadata &&
              widget.hadith.sharhMetadata != null)
            _buildSharhSection(theme, colors),

          // Related Hadiths Links
          if (widget.hadith.hasSimilarHadith ||
              widget.hadith.hasAlternateHadithSahih ||
              widget.hadith.hasUsulHadith)
            _buildRelatedLinks(theme, colors),
        ],
      ),
    );
  }

  Widget _buildBookInfo(FThemeData theme, FColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(FIcons.book, size: 20, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المصدر',
                  style: theme.typography.sm.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.hadith.book,
                  style: theme.typography.base.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.hadith.numberOrPage,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.secondary.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FIcons.info, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'شرح الحكم',
                style: theme.typography.sm.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.hadith.explainGrade!, style: theme.typography.sm),
        ],
      ),
    );
  }

  Widget _buildGradeSection(FThemeData theme, FColors colors) {
    final gradeColor = _getGradeColor(widget.hadith.grade, colors);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: gradeColor.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: gradeColor.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(FIcons.check, size: 20, color: gradeColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المحدث',
                      style: theme.typography.sm.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.hadith.mohdith,
                      style: theme.typography.base.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: gradeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.hadith.grade,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colors.secondary.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(widget.hadith.hadith),
    );
  }

  Widget _buildHadithText(FThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colors.secondary.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SelectableText(
        widget.hadith.hadith,
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: colors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.typography.sm.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 4),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.primary),
          const SizedBox(width: 8),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(
            'روابط ذات صلة',
            style: theme.typography.sm.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (widget.hadith.hasSimilarHadith)
            _buildLinkChip(
              icon: FIcons.copy,
              label: 'أحاديث مشابهة',
              colors: colors,
              theme: theme,
            ),
          if (widget.hadith.hasAlternateHadithSahih)
            _buildLinkChip(
              icon: FIcons.check,
              label: 'روايات صحيحة بديلة',
              colors: colors,
              theme: theme,
            ),
          if (widget.hadith.hasUsulHadith)
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

  Widget _buildSharhSection(FThemeData theme, FColors colors) {
    final sharh = widget.hadith.sharhMetadata!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.primary.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FIcons.bookOpen, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'الشرح',
                style: theme.typography.sm.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loadedSharh != null) ...[
            SelectableText(
              _loadedSharh!,
              style: theme.typography.sm.copyWith(height: 1.6),
            ),
          ] else if (_isLoadingSharh) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
          ] else if (_sharhError != null) ...[
            Text(
              _sharhError!,
              style: theme.typography.sm.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 8),
            FButton(
              onPress: () => _loadSharh(sharh.id),
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
                onPress: () => _loadSharh(sharh.id),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(FIcons.download, size: 16),
                    const SizedBox(width: 8),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.secondary.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FIcons.library, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'التخريج',
                style: theme.typography.sm.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.hadith.takhrij!, style: theme.typography.sm),
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

  Future<void> _loadSharh(String sharhId) async {
    setState(() {
      _isLoadingSharh = true;
      _sharhError = null;
    });

    try {
      final response = await _client.sharh.getById(sharhId);
      setState(() {
        _loadedSharh = response.sharhText;
        _isLoadingSharh = false;
      });
    } catch (e) {
      setState(() {
        _sharhError = 'فشل تحميل الشرح: $e';
        _isLoadingSharh = false;
      });
    }
  }
}
