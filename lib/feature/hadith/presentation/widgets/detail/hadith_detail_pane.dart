import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_sharh_text.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_result_card.dart';
import 'package:tawaq/theme/theme.dart';

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
    final expandedSections = useState<Set<int>>({});
    final hadithId = hadith.hadithId;
    const sharhSectionIndex = 0;
    final isSharhExpanded =
        hadith.hasSharhMetadata &&
        expandedSections.value.contains(sharhSectionIndex);

    final accordionItems = <FAccordionItem>[
      if (hadith.hasSharhMetadata)
        FAccordionItem(
          title: _sectionTitle(
            colors,
            FLucideIcons.bookOpenText,
            l10n.hadithSharh,
          ),
          child: isSharhExpanded
              ? HadithAsyncDetailsSection<Sharh>(
                  value: ref.watch(
                    hadithSharhProvider(hadith.sharhMetadata!.id),
                  ),
                  dataBuilder: (sharh) {
                    final text = sharh.sharhText;
                    if (text == null || text.trim().isEmpty) {
                      return const HadithSectionPlaceholder();
                    }
                    return HadithSharhText(text: text);
                  },
                )
              : const SizedBox.shrink(),
        ),
      if (hadith.hasUsulHadith && hadithId != null)
        FAccordionItem(
          title: _sectionTitle(
            colors,
            FLucideIcons.sparkles,
            l10n.hadithUsulHadith,
          ),
          child: HadithAsyncDetailsSection<UsulHadith>(
            value: ref.watch(hadithUsulProvider(hadithId)),
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
        FAccordionItem(
          title: _sectionTitle(
            colors,
            FLucideIcons.eye,
            l10n.hadithSimilarHadith,
          ),
          child: HadithAsyncDetailsSection<List<DetailedHadith>>(
            value: ref.watch(hadithSimilarProvider(hadithId)),
            dataBuilder: (items) {
              if (items.isEmpty) {
                return const HadithSectionPlaceholder();
              }

              return Column(
                spacing: AppSpacing.sm,
                children: items
                    .map(
                      (item) => HadithResultCard(
                        hadith: item,
                        onSelect: () {
                          unawaited(
                            ref
                                .read(
                                  hadithScreenControllerProvider.notifier,
                                )
                                .openSpecificList(
                                  items,
                                  selected: item,
                                ),
                          );
                        },
                        isFavorite: false,
                        isSelected: false,
                        showMetadataAvailability: false,
                        showFavoriteAction: false,
                        hadithMaxLines: 6,
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ),
      if (hadith.hasAlternateHadithSahih && hadithId != null)
        FAccordionItem(
          title: _sectionTitle(
            colors,
            FLucideIcons.arrowRightFromLine,
            l10n.hadithAlternateHadithSahih,
          ),
          child: HadithAsyncDetailsSection<DetailedHadith?>(
            value: ref.watch(hadithAlternateProvider(hadithId)),
            dataBuilder: (alternate) {
              if (alternate == null) {
                return const HadithSectionPlaceholder();
              }

              return HadithResultCard(
                hadith: alternate,
                onSelect: () {
                  unawaited(
                    ref
                        .read(hadithScreenControllerProvider.notifier)
                        .selectHadith(alternate),
                  );
                },
                isFavorite: false,
                isSelected: false,
                showMetadataAvailability: false,
                showFavoriteAction: false,
                hadithMaxLines: 6,
              );
            },
          ),
        ),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.sm),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow =
                constraints.maxWidth < context.theme.breakpoints.sm;
            return Text(
              hadith.hadith,
              textAlign: narrow ? TextAlign.start : TextAlign.justify,
              style: theme.typography.lg.copyWith(height: 1.8),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        HadithMetaItem(title: l10n.hadithNarrator, value: hadith.rawi),
        HadithMetaItem(title: l10n.hadithMuhaddith, value: hadith.mohdith),
        HadithMetaItem(
          title: l10n.hadithSource,
          value: l10n.hadithSourceCitation(
            hadith.book,
            hadith.numberOrPage,
          ),
        ),
        HadithMetaItem(
          title: l10n.hadithGradeExplanation,
          value: hadith.hukm,
        ),
        if ((hadith.takhrij ?? '').trim().isNotEmpty)
          HadithMetaItem(title: l10n.hadithTakhrij, value: hadith.takhrij!),
        if (accordionItems.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          FAccordion(
            control: FAccordionControl.lifted(
              expanded: expandedSections.value.contains,
              onChange: (index, isExpanded) {
                final next = Set<int>.from(expandedSections.value);
                if (isExpanded) {
                  next.add(index);
                } else {
                  next.remove(index);
                }
                expandedSections.value = next;
              },
            ),
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
          style: theme.typography.sm.copyWith(color: theme.colors.destructive),
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
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
          Text(
            source.chain,
            style: theme.typography.sm,
            textAlign: TextAlign.justify,
          ),
          Text(
            source.hadithText,
            style: theme.typography.md,
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
      style: context.theme.typography.md.copyWith(
        color: context.theme.colors.mutedForeground,
      ),
    );
  }
}

class HadithMetaItem extends StatelessWidget {
  const HadithMetaItem({required this.title, required this.value, super.key});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(
            title,
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
          Text(
            value,
            style: theme.typography.md,
          ),
        ],
      ),
    );
  }
}
