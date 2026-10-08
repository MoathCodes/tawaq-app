import 'package:tawaq/feature/hadith/domain/models/hadith_display_text.dart';
import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_identity.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_judgment.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_failure_message.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_reader_scroll.dart';
import 'package:tawaq/core/utils/external_link_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_sharh_text.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_meta_field.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_source_ruling.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_result_card.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/share/hadith_share_actions.dart';
import 'package:tawaq/theme/theme.dart';

/// Full reader with a persistent action row and one source-aware content scroll.
class HadithSelectedDetailsPane extends HookConsumerWidget {
  const HadithSelectedDetailsPane({
    required this.hadith,
    this.onClose,
    super.key,
  });
  final VoidCallback? onClose;
  final DetailedHadith hadith;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final controller = ref.read(hadithSessionControllerProvider.notifier);
    final entry = ref.read(hadithSessionControllerProvider).reader;
    final selectedSection = useState(entry?.section);
    useEffect(() {
      selectedSection.value = entry?.section;
      return null;
    }, [hadithStableKey(hadith)]);
    var sectionReady = true;
    Widget load<T>({
      required AsyncValue<T> value,
      required VoidCallback onRetry,
      required Widget Function(T) dataBuilder,
    }) {
      sectionReady = !value.isLoading;
      return HadithAsyncDetailsSection<T>(
        value: value,
        onRetry: onRetry,
        dataBuilder: dataBuilder,
      );
    }

    // Old saved records may contain an unusable remote identifier. Keep their
    // sourced content readable without constructing an invalid endpoint.
    HadithRecordId? recordId;
    try {
      if (hadith.hadithId case final value?) recordId = HadithRecordId(value);
    } on ArgumentError {
      /* Local reader remains available. */
    }
    final id = recordId?.value;
    final explanation = hadith.explanationReference;
    final explanationId = explanation?.id ?? hadith.sharhMetadata?.id;
    void retry(VoidCallback action) {
      controller.retryInitialization();
      action();
    }

    Widget contextRecord(DetailedHadith record, {bool showNarration = true}) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: [
            if (showNarration)
              Text(hadithDisplayText(record), textDirection: TextDirection.rtl),
            HadithSourceRuling(
              hukm: hadithRulingText(record),
              tone: record.verdictTone,
            ),
            HadithMetaField(label: l10n.hadithNarrator, value: record.rawi),
            HadithMetaField(label: l10n.hadithMuhaddith, value: record.mohdith),
            HadithMetaField(
              label: l10n.hadithSource,
              value: l10n.hadithSourceCitation(
                record.book,
                record.numberOrPage,
              ),
            ),
          ],
        );
    final sections = <({String id, String label, Widget Function() build})>[
      if (explanationId != null)
        (
          id: 'explanation',
          label: l10n.hadithSharh,
          build: () => load<Sharh>(
            value: ref.watch(hadithSharhProvider(SharhId(explanationId))),
            onRetry: () => retry(
              () => ref.invalidate(hadithSharhProvider(SharhId(explanationId))),
            ),
            dataBuilder: (value) => HadithSharhContent(
              sharh: value,
              origin: explanation,
              selectedHadith: hadith,
            ),
          ),
        ),
      if (hasHadithMetadata(hadith.takhrij ?? ''))
        (
          id: 'takhrij',
          label: l10n.hadithTakhrij,
          build: () => Text(hadith.takhrij!, textDirection: TextDirection.rtl),
        ),
      if (id != null && hadith.asbabAvailability == Availability.advertised)
        (
          id: 'asbab',
          label: l10n.hadithAsbab,
          build: () => load<ApiResponse<AsbabResult>>(
            value: ref.watch(hadithAsbabProvider(HadithRecordId(id))),
            onRetry: () => retry(
              () => ref.invalidate(hadithAsbabProvider(HadithRecordId(id))),
            ),
            dataBuilder: (response) => response.data.narrations.isEmpty
                ? const HadithSectionPlaceholder()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.lg,
                    children: [
                      Text(
                        l10n.hadithRelatedSource,
                        style: theme.typography.body.sm,
                      ),
                      contextRecord(response.data.source),
                      for (final narration in response.data.narrations)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: AppSpacing.sm,
                          children: [
                            if (narration.rawLabel.isNotEmpty)
                              Text(narration.rawLabel),
                            HadithSharhText(
                              document: narration.document,
                              text: narration.document.sourceText,
                            ),
                            contextRecord(
                              narration.hadith,
                              showNarration: false,
                            ),
                            FButton(
                              variant: .outline,
                              onPress: () =>
                                  controller.pushReader(narration.hadith),
                              child: Text(l10n.hadithDetailsTab),
                            ),
                          ],
                        ),
                    ],
                  ),
          ),
        ),
      if (id != null &&
          (hadith.hasUsulHadith ||
              hadith.usulAvailability == Availability.advertised))
        (
          id: 'usul',
          label: l10n.hadithUsulHadith,
          build: () => load<ApiResponse<UsulHadith>>(
            value: ref.watch(hadithUsulProvider(HadithRecordId(id))),
            onRetry: () => retry(
              () => ref.invalidate(hadithUsulProvider(HadithRecordId(id))),
            ),
            dataBuilder: (response) => response.data.sources.isEmpty
                ? const HadithSectionPlaceholder()
                : Column(
                    spacing: AppSpacing.lg,
                    children: [
                      for (final source in response.data.sources)
                        HadithUsulSourceCard(source: source),
                    ],
                  ),
          ),
        ),
      for (final kind in RelatedHadithKind.values)
        if (id != null &&
            (kind == RelatedHadithKind.similar
                ? hadith.hasSimilarHadith
                : hadith.hasAlternateHadithSahih))
          (
            id: kind.name,
            label: kind == RelatedHadithKind.similar
                ? l10n.hadithSimilarHadith
                : l10n.hadithAlternateHadithSahih,
            build: () => load<ApiResponse<RelatedHadithResult>>(
              value: ref.watch(hadithRelatedProvider(HadithRecordId(id), kind)),
              onRetry: () => retry(
                () => ref.invalidate(
                  hadithRelatedProvider(HadithRecordId(id), kind),
                ),
              ),
              dataBuilder: (response) => response.data.related.isEmpty
                  ? const HadithSectionPlaceholder()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpacing.lg,
                      children: [
                        if (response.data.source case final source?) ...[
                          Text(l10n.hadithRelatedSource),
                          contextRecord(source),
                        ],
                        for (final record in response.data.related)
                          HadithResultCard.embedded(
                            hadith: record,
                            onSelect: () => controller.pushReader(record),
                          ),
                      ],
                    ),
            ),
          ),
    ];
    final index = sections.indexWhere((s) => s.id == selectedSection.value);
    final firstMeaningful = sections.indexWhere(
      (s) =>
          s.id == 'explanation' ||
          s.id == 'takhrij' ||
          (s.id == 'asbab' &&
              hadith.asbabAvailability == Availability.advertised) ||
          (s.id == 'usul' &&
              (hadith.hasUsulHadith ||
                  hadith.usulAvailability == Availability.advertised)) ||
          s.id == RelatedHadithKind.similar.name ||
          s.id == RelatedHadithKind.alternate.name,
    );
    final active = index < 0
        ? (firstMeaningful < 0 ? 0 : firstMeaningful)
        : index;
    final sectionBody = sections.isEmpty ? null : sections[active].build();
    final favorites = ref.watch(hadithFavoritesProvider).value ?? [];
    final saved = favorites.any(
      (r) => hadithStableKey(r) == hadithStableKey(hadith),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (ref.watch(
                  hadithSessionControllerProvider.select(
                    (s) => s.readerTrail.length,
                  ),
                ) >
                1)
              FButton.icon(
                variant: .ghost,
                semanticsTooltip: l10n.back,
                onPress: controller.readerBack,
                child: const Icon(FLucideIcons.undo2, size: 16),
              ),
            HadithShareActions(
              hadith: hadith,
              favoriteButton: FButton.icon(
                variant: .ghost,
                semanticsTooltip: l10n.bookmarks,
                onPress: () async {
                  try {
                    await controller.toggleFavorite(hadith);
                  } catch (_) {
                    if (context.mounted)
                      showFToast(
                        context: context,
                        title: Text(l10n.hadithBookmarkFailed),
                      );
                  }
                },
                child: Icon(
                  saved ? FLucideIcons.bookmarkCheck : FLucideIcons.bookmark,
                  size: 16,
                ),
              ),
            ),
            if (entry != null)
              FButton.icon(
                variant: .ghost,
                semanticsTooltip: l10n.hadithCloseReader,
                onPress: onClose ?? controller.clearSelection,
                child: const Icon(FLucideIcons.x, size: 16),
              ),
          ],
        ),
        const FDivider(),
        Expanded(
          child: HadithReaderScroll(
            key: ValueKey(hadithStableKey(hadith)),
            initialOffset: entry?.offset ?? 0,
            ready: sectionReady,
            onOffsetChanged: (offset) =>
                controller.setReaderPosition(offset: offset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                SelectableText(
                  hadithDisplayText(hadith),
                  textDirection: TextDirection.rtl,
                  style: theme.typography.body.xl.copyWith(
                    fontSize: (theme.typography.body.xl.fontSize ?? 20) * 1.2,
                    height: 1.8,
                  ),
                ),
                HadithSourceRuling(
                  hukm: hadithRulingText(hadith),
                  tone: hadith.verdictTone,
                ),
                HadithMetaField(
                  label: l10n.hadithNarrator,
                  value: hadith.rawi,
                  layout: HadithMetaFieldLayout.row,
                ),
                HadithMetaField(
                  label: l10n.hadithMuhaddith,
                  layout: HadithMetaFieldLayout.row,
                  value: hadith.mohdith,
                ),
                HadithMetaField(
                  label: l10n.hadithSource,
                  layout: HadithMetaFieldLayout.row,
                  value: l10n.hadithSourceCitation(
                    hadith.book,
                    hadith.numberOrPage,
                  ),
                ),
                if (id == null) Text(l10n.hadithNoRemoteId),
                if (sections.isNotEmpty)
                  FTabs(
                    key: ValueKey(
                      '${hadithStableKey(hadith)}:${sections.map((s) => s.id).join(",")}',
                    ),
                    scrollable: true,
                    expands: false,
                    style: FTabsStyleDelta.delta(
                      decoration: DecorationDelta.value(
                        BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: theme.colors.border),
                          ),
                        ),
                      ),
                      indicatorDecoration: DecorationDelta.value(
                        BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: theme.colors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      padding: const EdgeInsetsGeometryDelta.value(
                        EdgeInsets.zero,
                      ),
                    ),
                    control: FTabControl.lifted(
                      index: active,
                      onChange: (value) {
                        selectedSection.value = sections[value].id;
                        controller.setReaderPosition(
                          section: sections[value].id,
                        );
                      },
                    ),
                    children: [
                      for (final (i, section) in sections.indexed)
                        FTabEntry(
                          label: Text(section.label),
                          child: i == active
                              ? sectionBody!
                              : const SizedBox.shrink(),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class HadithAsyncDetailsSection<T> extends StatelessWidget {
  const new({
    required this.value,
    required this.dataBuilder,
    required this.onRetry,
    super.key,
  });

  final VoidCallback onRetry;
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
      AsyncError() => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Text(
              hadithFailureMessage(value.error, context.l10n),
              style: theme.typography.body.sm.copyWith(
                color: theme.colors.destructive,
              ),
            ),
            FButton(
              variant: .secondary,
              onPress: onRetry,
              child: Text(context.l10n.retryAction),
            ),
          ],
        ),
      ),
      AsyncData(:final value) => dataBuilder(value),
    };
  }
}

class HadithUsulSourceCard extends StatelessWidget {
  const new({required this.source, super.key});

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
          HadithSharhText(document: source.chainContent, text: source.chain),
          HadithSharhText(
            document: source.narrationContent,
            text: source.hadithText,
          ),
        ],
      ),
    );
  }
}

class HadithSectionPlaceholder extends StatelessWidget {
  const new({super.key});

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

/// A prose result opens its explanation without becoming a bookmarkable record.
class HadithProseDetailsPane extends ConsumerWidget {
  const HadithProseDetailsPane({required this.id, this.onClose, super.key});
  final VoidCallback? onClose;
  final SharhId id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(hadithSessionControllerProvider.notifier);
    final value = ref.watch(hadithSharhProvider(id));
    final entry = ref.read(hadithSessionControllerProvider).reader;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            FButton(
              variant: .ghost,
              mainAxisSize: MainAxisSize.min,
              child: Text(context.l10n.hadithSource),
              onPress: () => ref.read(externalLinkLauncherProvider)(
                Uri.https('dorar.net', '/sharh/${id.value}'),
              ),
            ),
            if (entry != null)
              FButton.icon(
                variant: .ghost,
                semanticsTooltip: context.l10n.hadithCloseReader,
                onPress: onClose ?? controller.clearSelection,
                child: const Icon(FLucideIcons.x, size: 16),
              ),
          ],
        ),
        const FDivider(),
        Expanded(
          child: HadithReaderScroll(
            key: ValueKey('prose:${id.value}'),
            initialOffset: entry?.offset ?? 0,
            ready: !value.isLoading,
            onOffsetChanged: (offset) =>
                controller.setReaderPosition(offset: offset),
            child: HadithAsyncDetailsSection<Sharh>(
              value: value,
              onRetry: () {
                controller.retryInitialization();
                ref.invalidate(hadithSharhProvider(id));
              },
              dataBuilder: (sharh) => HadithSharhContent(sharh: sharh),
            ),
          ),
        ),
      ],
    );
  }
}
