import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_sharh_text.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_meta_field.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_result_card.dart';
import 'package:tawaq/theme/theme.dart';

class HadithSelectedDetailsPane extends ConsumerWidget {
  const HadithSelectedDetailsPane({required this.hadith, super.key});

  final DetailedHadith hadith;

  Widget _sectionTitle(FColors colors, IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 16, color: colors.primary),
      const SizedBox(width: AppSpacing.sm),
      Text(text),
    ],
  );

  List<FAccordionItem> _accordionItems(
    BuildContext context,
    WidgetRef ref,
    FColors colors,
  ) {
    final l10n = context.l10n;
    final hadithId = hadith.hadithId;
    final items = <FAccordionItem>[];

    void addSection({
      required bool visible,
      required IconData icon,
      required String title,
      required Widget child,
    }) {
      if (!visible) return;
      items.add(
        FAccordionItem(
          title: _sectionTitle(colors, icon, title),
          child: child,
        ),
      );
    }

    addSection(
      visible: hadith.hasSharhMetadata,
      icon: FLucideIcons.bookOpenText,
      title: l10n.hadithSharh,
      child: HadithAsyncDetailsSection<Sharh>(
        value: ref.watch(hadithSharhProvider(hadith.sharhMetadata!.id)),
        dataBuilder: (sharh) {
          final text = sharh.sharhText;
          if (text == null || text.trim().isEmpty) {
            return const HadithSectionPlaceholder();
          }
          return HadithSharhText(text: text);
        },
      ),
    );

    addSection(
      visible: hadith.hasUsulHadith && hadithId != null,
      icon: FLucideIcons.sparkles,
      title: l10n.hadithUsulHadith,
      child: HadithAsyncDetailsSection<UsulHadith>(
        value: ref.watch(hadithUsulProvider(hadithId!)),
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
    );

    addSection(
      visible: hadith.hasSimilarHadith,
      icon: FLucideIcons.eye,
      title: l10n.hadithSimilarHadith,
      child: HadithAsyncDetailsSection<List<DetailedHadith>>(
        value: ref.watch(hadithSimilarProvider(hadithId)),
        dataBuilder: (similarItems) {
          if (similarItems.isEmpty) {
            return const HadithSectionPlaceholder();
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: similarItems.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
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
    );

    addSection(
      visible: hadith.hasAlternateHadithSahih,
      icon: FLucideIcons.arrowRightFromLine,
      title: l10n.hadithAlternateHadithSahih,
      child: HadithAsyncDetailsSection<DetailedHadith?>(
        value: ref.watch(hadithAlternateProvider(hadithId)),
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
    );

    return items;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final accordionItems = _accordionItems(context, ref, colors);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          if (accordionItems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            FAccordion(
              style: .delta(
                dividerStyle: .delta(
                  color: colors.border,
                  padding: const .value(EdgeInsets.zero),
                ),
              ),
              children: accordionItems,
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
          style: theme.typography.body.sm.copyWith(color: theme.colors.destructive),
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
