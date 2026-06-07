import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/muslim_fortress_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_a11y.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_commentary_text.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

String _fortressStudyHeading(
  FortressDuaItem dua,
  AppLocalizations l10n, {
  required bool dialogTitle,
}) {
  if (dua.studySectionLabels(l10n).length > 1) {
    return l10n.fortressShowDetails;
  }
  return switch (dua) {
    _ when dua.hasSharh =>
      dialogTitle ? l10n.fortressSharh : l10n.fortressShowSharh,
    _ when dua.hasSource =>
      dialogTitle ? l10n.fortressSourceReference : l10n.fortressShowSource,
    _ when dua.hasHadith => l10n.fortressRelatedHadith,
    _ when dua.hasBenefit => l10n.fortressBenefit,
    _ => l10n.fortressShowDetails,
  };
}

class _FortressStudySectionHeader extends StatelessWidget {
  const _FortressStudySectionHeader({
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
            style: (prominent ? typography.md : typography.sm).copyWith(
              fontWeight: FontWeight.w700,
              color: prominent ? colors.primary : colors.foreground,
            ),
          ),
        ],
      ),
    );
  }
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
    builder: (context, style, animation) => FDialog(
      title: Text(_fortressStudyHeading(dua, l10n, dialogTitle: true)),
      body: SizedBox(
        width: 640,
        height: 520,
        child: DesktopSelectionArea(
          child: SingleChildScrollView(
            child: FortressDuaStudyContent(dua: dua),
          ),
        ),
      ),
      actions: [
        FButton(
          onPress: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    ),
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

    final label = _fortressStudyHeading(dua, l10n, dialogTitle: false);

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
            child: Column(
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
                    Text(
                      label,
                      style: theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (showIncludes) ...[
                  const SizedBox(height: 2),
                  Text(
                    sections.join(' · '),
                    style: theme.typography.xs.copyWith(
                      color: theme.colors.mutedForeground,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Always-visible الفضل line (focus reading footer).
class FortressDuaVirtueLine extends HookWidget {
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
    final proseStyle = useMemoized(
      () => theme.typography.sm.copyWith(
        color: theme.colors.mutedForeground,
        height: 1.75,
        fontFamily: FontFamily.iBMPlexSansArabic,
      ),
      [theme.typography.sm, theme.colors.mutedForeground, theme.isDark],
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
      style: theme.typography.sm.copyWith(
        color: theme.colors.mutedForeground,
        height: 1.6,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Opens sharh / virtue / supplements on demand ([useSheet]) or inline expand.
class FortressDuaStudyAccess extends HookWidget {
  /// Creates study access controls.
  const FortressDuaStudyAccess({
    required this.dua,
    this.useSheet = false,
    super.key,
  });

  /// The dhikr item.
  final FortressDuaItem dua;

  /// When true, content opens in a dialog (focus mode). Otherwise expands inline.
  final bool useSheet;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final expanded = useState(false);

    if (!dua.hasStudyContent) {
      return const SizedBox.shrink();
    }

    final isOpen = !useSheet && expanded.value;
    final label = isOpen
        ? l10n.fortressHideDetails
        : _fortressStudyHeading(dua, l10n, dialogTitle: false);
    final actionIcon = isOpen
        ? FLucideIcons.chevronUp
        : FLucideIcons.bookOpenText;

    void openStudy() {
      if (useSheet) {
        unawaited(showFortressStudySheet(context, dua));
        return;
      }
      expanded.value = !expanded.value;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: IntrinsicWidth(
            child: NonSelectable(
              child: FButton(
                variant: .outline,
                onPress: openStudy,
                prefix: Icon(actionIcon, size: 18),
                child: Text(label),
              ),
            ),
          ),
        ),
        if (!useSheet)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: expanded.value
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: FortressDuaStudyContent(dua: dua, compact: true),
            ),
          ),
      ],
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;
    final l10n = context.l10n;
    final proseStyle = useMemoized(
      () {
        final scale = compact ? typography.sm : typography.md;
        return scale.copyWith(
          color: colors.foreground,
          height: 1.75,
          fontFamily: FontFamily.iBMPlexSansArabic,
        );
      },
      [compact, typography.sm, typography.md, colors.foreground, theme.isDark],
    );

    final commentaryAsync = dua.commentary != null
        ? AsyncValue.data(dua.commentary)
        : dua.hasCommentary
        ? ref.watch(muslimFortressCommentaryProvider(dua.contentId))
        : const AsyncValue.data(null);

    return switch (commentaryAsync) {
      AsyncLoading() => const Center(child: FCircularProgress.loader()),
      AsyncError(:final error) => Text(
        '$error',
        style: typography.sm.copyWith(color: colors.destructive),
      ),
      AsyncData(:final value) => _StudyBody(
        dua: dua,
        commentary: value,
        compact: compact,
        proseStyle: proseStyle,
        l10n: l10n,
        colors: colors,
        typography: typography,
      ),
    };
  }
}

class _StudyBody extends StatelessWidget {
  const _StudyBody({
    required this.dua,
    required this.commentary,
    required this.compact,
    required this.proseStyle,
    required this.l10n,
    required this.colors,
    required this.typography,
  });

  final FortressDuaItem dua;
  final HisnCommentary? commentary;
  final bool compact;
  final TextStyle proseStyle;
  final AppLocalizations l10n;
  final FColors colors;
  final FTypography typography;

  @override
  Widget build(BuildContext context) {
    final sharh = commentary?.sharh;
    final hasSharhBody = sharh != null && sharh.trim().isNotEmpty;
    final promisedSharh = dua.hasSharh;
    final source = dua.reference;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (promisedSharh) ...[
          _FortressStudySectionHeader(
            icon: FLucideIcons.bookOpenText,
            title: l10n.fortressSharh,
            prominent: true,
          ),
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
          if (hasSharhBody)
            FortressCommentaryText(
              text: sharh,
              baseStyle: proseStyle,
            )
          else
            Text(
              l10n.noDataAvailable,
              style: typography.md.copyWith(color: colors.mutedForeground),
            ),
        ],
        if (promisedSharh)
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
        _FortressSecondaryInsights(
          hadith: commentary?.hadith,
          benefit: commentary?.benefit,
          proseStyle: proseStyle,
        ),
        if (dua.hasSource) ...[
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
          _FortressStudySectionHeader(
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
              style: const .delta(
                padding: .value(EdgeInsets.all(2)),
                indicatorSize: FTabBarIndicatorSize.tab,
              ),
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
          _FortressStudySectionHeader(
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
