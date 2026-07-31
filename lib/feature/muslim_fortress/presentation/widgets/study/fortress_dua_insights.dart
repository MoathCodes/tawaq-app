import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/dialog_shell.dart';
import 'package:tawaq/feature/muslim_fortress/data/repository/fortress_repository.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_nav_controls.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_commentary_text.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

String _fortressStudyLabel(
  FortressDuaItem dua,
  AppLocalizations l10n, {
  bool forDialog = false,
}) {
  if (dua.studySectionLabels(l10n).length > 1) {
    return l10n.fortressShowDetails;
  }
  return switch (dua) {
    _ when dua.hasSharh =>
      forDialog ? l10n.fortressSharh : l10n.fortressShowSharh,
    _ when dua.hasSource =>
      forDialog ? l10n.fortressSourceReference : l10n.fortressShowSource,
    _ when dua.hasHadith => l10n.fortressRelatedHadith,
    _ when dua.hasBenefit => l10n.fortressBenefit,
    _ => l10n.fortressShowDetails,
  };
}

/// Opens sharh / source / supplements in a dialog (focus reading).
Future<void> showFortressStudySheet(
  BuildContext context,
  FortressDuaItem dua,
) {
  if (!dua.hasStudyContent) return Future.value();

  final l10n = context.l10n;
  return showFDialog<void>(
    context: context,
    builder: (dialogContext, style, animation) {
      final constraints = dialogConstraints(
        dialogContext,
        preferredWidth: 640,
        preferredHeight: 520,
        minWidth: 280,
      );

      return FDialog(
        style: style,
        animation: animation,
        constraints: constraints,
        builder: (context, dialogStyle) => ForuiDialogLayout(
          style: dialogStyle,
          title: Text(_fortressStudyLabel(dua, l10n, forDialog: true)),
          body: DesktopSelectionArea(
            child: SingleChildScrollView(
              child: FortressDuaStudyContent(dua: dua),
            ),
          ),
          actions: [
            FButton(
              onPress: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      );
    },
  );
}

/// Compact study control in the focus-reading nav cluster.
class FortressDuaStudyNavAction extends StatelessWidget {
  /// Creates a study nav action.
  const FortressDuaStudyNavAction({required this.dua, super.key});

  final FortressDuaItem dua;

  @override
  Widget build(BuildContext context) {
    if (!dua.hasStudyContent) {
      return const SizedBox.shrink();
    }

    final theme = context.theme;
    final l10n = context.l10n;
    final sections = dua.studySectionLabels(l10n);
    final showIncludes = sections.length > 1;

    final label = _fortressStudyLabel(dua, l10n);

    return Center(
      child: IntrinsicWidth(
        child: FortressLabeledNavButton(
          label: '${dua.category}. $label',
          enabled: true,
          onPress: () => unawaited(showFortressStudySheet(context, dua)),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: showIncludes
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FLucideIcons.bookOpenText,
                            size: 16,
                            color: theme.colors.foreground,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              label,
                              style: theme.typography.body.sm.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sections.join(' · '),
                        style: theme.typography.body.xs.copyWith(
                          color: theme.colors.mutedForeground,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FLucideIcons.bookOpenText,
                        size: 16,
                        color: theme.colors.foreground,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          label,
                          style: theme.typography.body.sm.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Always-visible الفضل line (focus reading footer).
class FortressDuaVirtueLine extends StatelessWidget {
  /// Creates a virtue line.
  const FortressDuaVirtueLine({
    required this.virtue,
    super.key,
  });

  /// Fadl text.
  final String virtue;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final proseStyle = theme.typography.body.sm.copyWith(
      color: theme.colors.mutedForeground,
      height: 1.75,
    );

    return FortressCommentaryText(
      text: virtue,
      baseStyle: proseStyle,
      textAlign: TextAlign.center,
    );
  }
}

/// Takhreej / مصدر line (shown inside on-demand study content).
class FortressDuaSourceLine extends StatelessWidget {
  /// Creates a source line.
  const FortressDuaSourceLine({
    required this.reference,
    super.key,
  });

  /// Takhreej text.
  final String reference;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return ScopedSelectableText(
      reference,
      style: theme.typography.body.sm.copyWith(
        color: theme.colors.mutedForeground,
        height: 1.6,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Sharh-first study body (used in sheet or inline expansion).
class FortressDuaStudyContent extends HookConsumerWidget {
  /// Creates study content.
  const FortressDuaStudyContent({
    required this.dua,
    this.compact = false,
    super.key,
  });

  final FortressDuaItem dua;
  final bool compact;

  TextStyle _proseStyle(FTypography typography, FColors colors) {
    final scale = compact ? typography.body.sm : typography.body.md;
    return scale.copyWith(
      color: colors.foreground,
      height: 1.75,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;
    final l10n = context.l10n;
    final proseStyle = _proseStyle(typography, colors);
    final commentaryState = useState<HisnCommentary?>(dua.commentary);
    final isLoading = useState(dua.commentary == null && dua.hasCommentary);

    useEffect(
      () {
        if (dua.commentary != null || !dua.hasCommentary) {
          return null;
        }

        var cancelled = false;
        unawaited(
          ref.read(fortressRepositoryProvider.future).then((repository) {
            if (cancelled) return;
            commentaryState.value =
                repository.loadCommentaryForContent(dua.contentId);
            isLoading.value = false;
          }),
        );

        return () => cancelled = true;
      },
      [dua.contentId],
    );

    if (isLoading.value) {
      return const Center(child: FCircularProgress.loader());
    }

    final commentary = commentaryState.value;
    final sharh = commentary?.sharh;
    final hasSharh = sharh != null && sharh.isNotEmpty;
    final source = dua.reference;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasSharh) ...[
          _StudySectionHeader(
            icon: FLucideIcons.bookOpenText,
            title: l10n.fortressSharh,
            prominent: true,
          ),
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
          FortressCommentaryText(
            text: sharh,
            baseStyle: proseStyle,
          ),
        ],
        if (hasSharh) SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
        _FortressSecondaryInsights(
          hadith: commentary?.hadith,
          benefit: commentary?.benefit,
          proseStyle: proseStyle,
        ),
        if (dua.hasSource) ...[
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
          _StudySectionHeader(
            icon: FLucideIcons.bookMarked,
            title: l10n.fortressSourceReference,
          ),
          const SizedBox(height: AppSpacing.sm),
          FortressDuaSourceLine(reference: source!),
        ],
      ],
    );
  }
}

/// Hadith and benefit supplements — tabbed only when both are present.
class _FortressSecondaryInsights extends HookWidget {
  const _FortressSecondaryInsights({
    required this.hadith,
    required this.benefit,
    required this.proseStyle,
  });

  final String? hadith;
  final String? benefit;
  final TextStyle proseStyle;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final tabIndex = useState(0);

    final hasHadith = hadith != null && hadith!.trim().isNotEmpty;
    final hasBenefit = benefit != null && benefit!.trim().isNotEmpty;

    if (!hasHadith && !hasBenefit) {
      return const SizedBox.shrink();
    }

    Widget body(String content) {
      return FortressCommentaryText(
        text: content,
        baseStyle: proseStyle,
      );
    }

    if (hasHadith && hasBenefit) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NonSelectable(
            child: FTabs(
              control: FTabControl.lifted(
                index: tabIndex.value,
                onChange: (index) => tabIndex.value = index,
              ),
              style: theme.tabs.compact,
              children: [
                .entry(
                  label: Text(l10n.fortressBenefit),
                  child: const SizedBox.shrink(),
                ),
                .entry(
                  label: Text(l10n.fortressRelatedHadith),
                  child: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.secondary.withAlpha(60),
              borderRadius: theme.radii.md,
              border: Border.all(color: colors.border.withAlpha(120)),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: tabIndex.value == 0 ? body(benefit!) : body(hadith!),
            ),
          ),
        ],
      );
    }

    final singleTitle = hasHadith
        ? l10n.fortressRelatedHadith
        : l10n.fortressBenefit;
    final singleIcon = hasHadith
        ? FLucideIcons.scrollText
        : FLucideIcons.sparkles;
    final singleText = hasHadith ? hadith! : benefit!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.secondary.withAlpha(60),
        borderRadius: theme.radii.md,
        border: Border.all(color: colors.border.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StudySectionHeader(
            icon: singleIcon,
            title: singleTitle,
          ),
          const SizedBox(height: AppSpacing.md),
          body(singleText),
        ],
      ),
    );
  }
}

class _StudySectionHeader extends StatelessWidget {
  const _StudySectionHeader({
    required this.icon,
    required this.title,
    this.prominent = false,
  });

  final IconData icon;
  final String title;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;

    return Semantics(
      header: true,
      child: Row(
        children: [
          Icon(
            icon,
            size: prominent ? 20 : 16,
            color: prominent ? colors.primary : colors.mutedForeground,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: (prominent ? typography.body.md : typography.body.sm).copyWith(
              fontWeight: prominent ? FontWeight.w700 : FontWeight.w600,
              color: prominent ? colors.primary : colors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
