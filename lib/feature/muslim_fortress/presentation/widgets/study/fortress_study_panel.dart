import 'package:forui/forui.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/empty_state_panel.dart';
import 'package:tawaq/feature/muslim_fortress/data/repository/fortress_repository.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_commentary_text.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

enum FortressDetailKind {
  virtue,
  source,
  benefit,
  sharh,
  hadith;

  String label(AppLocalizations l10n) => switch (this) {
    virtue => l10n.fortressVirtue,
    source => l10n.fortressSourceReference,
    benefit => l10n.fortressBenefit,
    sharh => l10n.fortressSharh,
    hadith => l10n.fortressRelatedHadith,
  };

  static List<FortressDetailKind> available(FortressDuaItem dua) => [
    if (dua.hasDistinctVirtue) virtue,
    if (dua.hasSource) source,
    if (dua.hasBenefit) benefit,
    if (dua.hasSharh) sharh,
    if (dua.hasHadith) hadith,
  ];
}

final fortressStudyCommentaryProvider = FutureProvider.autoDispose
    .family<HisnCommentary?, int>((ref, id) async {
      final repository = await ref.watch(fortressRepositoryProvider.future);
      return repository.loadCommentaryForContent(id);
    });

/// A bounded, tabbed reader shared by docked sheets and browse details.
class FortressStudyPanel extends ConsumerWidget {
  const FortressStudyPanel({
    required this.dua,
    required this.kind,
    required this.onKindChanged,
    required this.onClose,
    required this.bucket,
    this.itemNumber,
    this.itemTotal,
    this.onExpand,
    this.expanded = false,
    this.paused = false,
    this.onNext,
    this.onPrevious,
    super.key,
  });

  final FortressDuaItem dua;
  final int? itemNumber;
  final int? itemTotal;
  final FortressDetailKind kind;
  final ValueChanged<FortressDetailKind> onKindChanged;
  final VoidCallback onClose;
  final VoidCallback? onExpand;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final PageStorageBucket bucket;
  final bool expanded;
  final bool paused;

  /// Width needed for full-width tabs to wrap at word boundaries, including
  /// the user's interface text scale. Single-field readers have no tab bar.
  static double minimumTabWidth(BuildContext context, FortressDuaItem dua) {
    final kinds = FortressDetailKind.available(dua);
    if (kinds.length < 2) return 0;
    final theme = context.theme;
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    );
    var widest = 0.0;
    try {
      for (final kind in kinds) {
        for (final word in kind.label(context.l10n).split(RegExp(r'\s+'))) {
          painter.text = TextSpan(
            text: word,
            style: theme.typography.body.xs.copyWith(
              fontWeight: FontWeight.w600,
            ),
          );
          painter.layout();
          if (painter.width > widest) widest = painter.width;
        }
      }
    } finally {
      painter.dispose();
    }
    final tabPadding = theme.tabs.compact.padding
        .resolve(Directionality.of(context))
        .horizontal;
    return (32 + tabPadding + kinds.length * (widest + 8) + 2).ceilToDouble();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = context.theme;
    final kinds = FortressDetailKind.available(dua);
    final selected = kinds.contains(kind) ? kind : kinds.first;
    Widget body(String? text) {
      if (text == null || text.trim().isEmpty) {
        return ErrorStatePanel(
          message: l10n.fortressShareDetailsFailed,
          retryLabel: l10n.fortressRetry,
          onRetry: () =>
              ref.invalidate(fortressStudyCommentaryProvider(dua.contentId)),
        );
      }
      return Directionality(
        textDirection: TextDirection.rtl,
        child: PageStorage(
          bucket: bucket,
          child: _DetailScrollBody(
            key: ValueKey((dua.contentId, selected)),
            storageKey: PageStorageKey((dua.contentId, selected)),
            text: text,
            source: selected == FortressDetailKind.source,
          ),
        ),
      );
    }

    final content = switch (selected) {
      FortressDetailKind.virtue => body(dua.virtue),
      FortressDetailKind.source => body(dua.source),
      _ =>
        dua.commentary != null
            ? body(_field(dua.commentary!, selected))
            : ref
                  .watch(fortressStudyCommentaryProvider(dua.contentId))
                  .when(
                    data: (commentary) => body(
                      commentary == null ? null : _field(commentary, selected),
                    ),
                    loading: () =>
                        const Center(child: FCircularProgress.loader()),
                    error: (_, _) => ErrorStatePanel(
                      message: l10n.fortressLoadError,
                      retryLabel: l10n.fortressRetry,
                      onRetry: () => ref.invalidate(
                        fortressStudyCommentaryProvider(dua.contentId),
                      ),
                    ),
                  ),
    };

    return DefaultTextStyle(
      style: theme.typography.body.md,
      child: ColoredBox(
        color: theme.colors.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.fortressShowDetails,
                      style: theme.typography.body.lg.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (onPrevious != null)
                    FButton.icon(
                      variant: .ghost,
                      onPress: onPrevious,
                      semanticsLabel: l10n.fortressPrevious,
                      child: const Icon(FLucideIcons.chevronLeft),
                    ),
                  if (onNext != null)
                    FButton.icon(
                      variant: .ghost,
                      onPress: onNext,
                      semanticsLabel: l10n.next,
                      child: const Icon(FLucideIcons.chevronRight),
                    ),
                  if (onExpand != null)
                    FButton.icon(
                      variant: .ghost,
                      onPress: onExpand,
                      semanticsLabel: expanded
                          ? l10n.fortressRestoreDetails
                          : l10n.fortressExpandDetails,
                      child: Icon(
                        expanded
                            ? FLucideIcons.minimize2
                            : FLucideIcons.maximize2,
                      ),
                    ),
                  FButton.icon(
                    variant: .ghost,
                    onPress: onClose,
                    semanticsLabel: l10n.close,
                    child: const Icon(FLucideIcons.x),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                itemNumber == null
                    ? '${dua.category} · ${l10n.fortressItemIdentity(dua.contentId)}'
                    : '${dua.category} · ${l10n.fortressItemPosition(itemNumber!, itemTotal!)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.body.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),
            if (paused)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Text(
                  l10n.fortressStudyPaused,
                  style: theme.typography.body.xs.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: kinds.length == 1
                  ? Text(
                      selected.label(l10n),
                      style: theme.typography.body.md.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : TabBarTheme(
                      data: TabBarTheme.of(context).copyWith(
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      child: FTabs(
                        style: theme.tabs.compact,
                        scrollable: false,
                        control: .lifted(
                          index: kinds.indexOf(selected),
                          onChange: (index) => onKindChanged(kinds[index]),
                        ),
                        children: [
                          for (final tab in kinds)
                            .entry(
                              label: Text(
                                tab.label(l10n),
                                softWrap: true,
                                style: theme.typography.body.xs.copyWith(
                                  letterSpacing: 0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              child: const SizedBox.shrink(),
                            ),
                        ],
                      ),
                    ),
            ),
            Divider(height: 1, color: theme.colors.border),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  String _field(HisnCommentary commentary, FortressDetailKind kind) =>
      switch (kind) {
        FortressDetailKind.sharh => commentary.sharh,
        FortressDetailKind.hadith => commentary.hadith,
        FortressDetailKind.benefit => commentary.benefit,
        _ => '',
      };
}

class _DetailScrollBody extends StatefulWidget {
  const _DetailScrollBody({
    required this.storageKey,
    required this.text,
    required this.source,
    super.key,
  });
  final PageStorageKey<(int, FortressDetailKind)> storageKey;
  final String text;
  final bool source;

  @override
  State<_DetailScrollBody> createState() => _DetailScrollBodyState();
}

class _DetailScrollBodyState extends State<_DetailScrollBody> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
    controller: _scroll,
    child: SingleChildScrollView(
      key: widget.storageKey,
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: DesktopSelectionArea(
        child: FortressCommentaryText(
          text: widget.text,
          baseStyle: context.theme.typography.body.md.copyWith(
            fontSize: widget.source ? 16 : 18,
            height: 1.8,
          ),
        ),
      ),
    ),
  );
}
