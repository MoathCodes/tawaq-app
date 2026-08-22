import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_identity.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_sharh_text.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_meta_field.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_result_card.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/share/hadith_share_dialog.dart';
import 'package:tawaq/theme/theme.dart';

/// Detail pane for the selected hadith, with lazy accordion remote sections.
///
/// Forui's [FAccordion] always builds children (no lazy slot API); remote
/// [hadithDetailProvider] watches are gated via [FAccordionControl.lifted]
/// expanded tracking so collapsed sections do not fetch.
class HadithSelectedDetailsPane extends HookConsumerWidget {
  const HadithSelectedDetailsPane({required this.hadith, super.key});

  final DetailedHadith hadith;

  Widget _sectionTitle(FColors colors, IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 16, color: colors.primary),
      const SizedBox(width: AppSpacing.sm),
      Text(text),
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final expanded = useState(<int>{});
    final hadithId = hadith.hadithId;
    final stableKey = hadithStableKey(hadith);

    useEffect(() {
      expanded.value = {};
      return null;
    }, [stableKey]);

    final sections = <({IconData icon, String title, Widget Function() child})>[
      if (hadith.hasSharhMetadata)
        (
          icon: FLucideIcons.bookOpenText,
          title: l10n.hadithSharh,
          child: () => HadithAsyncDetailsSection<Sharh>(
            value: ref
                .watch(
                  hadithDetailProvider(
                    HadithDetailKind.sharh,
                    hadith.sharhMetadata!.id,
                  ),
                )
                .whenData((value) => value! as Sharh),
            dataBuilder: (sharh) {
              final text = sharh.sharhText;
              if (text == null || text.trim().isEmpty) {
                return const HadithSectionPlaceholder();
              }
              return HadithSharhText(text: text);
            },
          ),
        ),
      if (hadith.hasUsulHadith && hadithId != null)
        (
          icon: FLucideIcons.sparkles,
          title: l10n.hadithUsulHadith,
          child: () => HadithAsyncDetailsSection<UsulHadith>(
            value: ref
                .watch(
                  hadithDetailProvider(HadithDetailKind.usul, hadithId),
                )
                .whenData((value) => value! as UsulHadith),
            dataBuilder: (usul) {
              if (usul.sources.isEmpty) {
                return const HadithSectionPlaceholder();
              }

              return Column(
                spacing: AppSpacing.sm,
                children: usul.sources
                    .map((source) => HadithUsulSourceCard(source: source))
                    .toList(growable: false),
              );
            },
          ),
        ),
      if (hadith.hasSimilarHadith && hadithId != null)
        (
          icon: FLucideIcons.eye,
          title: l10n.hadithSimilarHadith,
          child: () => HadithAsyncDetailsSection<List<DetailedHadith>>(
            value: ref
                .watch(
                  hadithDetailProvider(HadithDetailKind.similar, hadithId),
                )
                .whenData((value) => value! as List<DetailedHadith>),
            dataBuilder: (similarItems) {
              if (similarItems.isEmpty) {
                return const HadithSectionPlaceholder();
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: similarItems.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final item = similarItems[index];
                  return HadithResultCard.embedded(
                    hadith: item,
                    onSelect: () {
                      unawaited(
                        ref
                            .read(hadithSessionControllerProvider.notifier)
                            .openSpecificList(similarItems, selected: item),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      if (hadith.hasAlternateHadithSahih && hadithId != null)
        (
          icon: FLucideIcons.arrowRightFromLine,
          title: l10n.hadithAlternateHadithSahih,
          child: () => HadithAsyncDetailsSection<DetailedHadith?>(
            value: ref
                .watch(
                  hadithDetailProvider(HadithDetailKind.alternate, hadithId),
                )
                .whenData((value) => value as DetailedHadith?),
            dataBuilder: (alternate) {
              if (alternate == null) {
                return const HadithSectionPlaceholder();
              }

              return HadithResultCard.embedded(
                hadith: alternate,
                onSelect: () {
                  unawaited(
                    ref
                        .read(hadithSessionControllerProvider.notifier)
                        .selectHadith(alternate),
                  );
                },
              );
            },
          ),
        ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FTooltip(
              tipBuilder: (_, _) => Text(l10n.hadithShare),
              child: FButton.icon(
                semanticsTooltip: l10n.hadithShare,
                variant: .ghost,
                onPress: () => showHadithShareDialog(context, hadith),
                child: const Icon(FLucideIcons.share2),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow =
                  constraints.maxWidth < context.theme.breakpoints.sm;
              return Text(
                hadith.hadith,
                textAlign: narrow ? TextAlign.start : TextAlign.justify,
                style: theme.typography.body.lg.copyWith(height: 1.8),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          HadithMetaField(label: l10n.hadithNarrator, value: hadith.rawi),
          HadithMetaField(label: l10n.hadithMuhaddith, value: hadith.mohdith),
          HadithMetaField(
            label: l10n.hadithSource,
            value: l10n.hadithSourceCitation(
              hadith.book,
              hadith.numberOrPage,
            ),
          ),
          HadithMetaField(
            label: l10n.hadithGradeExplanation,
            value: hadith.hukm,
          ),
          if ((hadith.takhrij ?? '').trim().isNotEmpty)
            HadithMetaField(
              label: l10n.hadithTakhrij,
              value: hadith.takhrij!,
            ),
          if (sections.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            FAccordion(
              control: FAccordionControl.lifted(
                expanded: expanded.value.contains,
                onChange: (index, isExpanded) {
                  final next = {...expanded.value};
                  if (isExpanded) {
                    next.add(index);
                  } else {
                    next.remove(index);
                  }
                  expanded.value = next;
                },
              ),
              style: .delta(
                dividerStyle: .delta(
                  color: colors.border,
                  padding: const .value(EdgeInsets.zero),
                ),
              ),
              children: [
                for (final (index, section) in sections.indexed)
                  FAccordionItem(
                    title: _sectionTitle(colors, section.icon, section.title),
                    child: expanded.value.contains(index)
                        ? section.child()
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class HadithAsyncDetailsSection<T> extends StatelessWidget {
  const HadithAsyncDetailsSection({
    required this.value,
    required this.dataBuilder,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T value) dataBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return switch (value) {
      AsyncLoading() => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: FCircularProgress.loader()),
      ),
      AsyncError(:final error) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          '$error',
          style: theme.typography.body.sm.copyWith(
            color: theme.colors.destructive,
          ),
        ),
      ),
      AsyncData(:final value) => dataBuilder(value),
    };
  }
}

class HadithUsulSourceCard extends StatelessWidget {
  const HadithUsulSourceCard({required this.source, super.key});

  final UsulSource source;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return StaticCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Text(
            source.source,
            style: theme.typography.body.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
          Text(
            source.chain,
            style: theme.typography.body.sm,
            textAlign: TextAlign.justify,
          ),
          Text(
            source.hadithText,
            style: theme.typography.body.md,
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}

class HadithSectionPlaceholder extends StatelessWidget {
  const HadithSectionPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      context.l10n.noDataAvailable,
      style: context.theme.typography.body.md.copyWith(
        color: context.theme.colors.mutedForeground,
      ),
    );
  }
}
