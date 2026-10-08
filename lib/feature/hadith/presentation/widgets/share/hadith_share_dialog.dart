import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/dialog_shell.dart';
import 'package:tawaq/core/widgets/share_card_dialog_layout.dart';
import 'package:tawaq/core/widgets/share_card_drag_surface.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_judgment.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_share_include.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/share/hadith_share_card.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/share/hadith_share_export.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/share/hadith_share_text.dart';
import 'package:tawaq/theme/theme.dart';

Future<void> showHadithShareDialog(
  BuildContext context,
  DetailedHadith hadith,
) {
  return showFDialog<void>(
    context: context,
    builder: (context, style, animation) =>
        HadithShareDialog(hadith: hadith, style: style, animation: animation),
  );
}

class HadithShareDialog extends HookConsumerWidget {
  const new({
    required this.hadith,
    required this.style,
    this.animation,
    super.key,
  });

  final DetailedHadith hadith;
  final FDialogStyle style;
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = context.theme;
    final boundaryKey = useMemoized(GlobalKey.new);
    final sharhAvailable =
        hadith.explanationReference != null || hadith.sharhMetadata != null;
    final usulAvailable =
        hadith.hadithId != null &&
        (hadith.hasUsulHadith ||
            hadith.usulAvailability == Availability.advertised);
    final options = useState(
      HadithShareOptions.defaults().constrained(
        hadith: hadith,
        sharhAvailable: sharhAvailable,
        usulAvailable: usulAvailable,
      ),
    );
    final judgmentRequired = requiresHadithJudgment(hadith);
    final isCapturing = useState(false);

    final sharhEnabled = options.value.contains(HadithShareInclude.sharh);
    final usulEnabled = options.value.contains(HadithShareInclude.usul);
    final AsyncValue<Sharh?> sharhState = sharhEnabled && sharhAvailable
        ? ref.watch(
            hadithSharhProvider(
              SharhId(
                hadith.explanationReference?.id ?? hadith.sharhMetadata!.id,
              ),
            ),
          )
        : const AsyncData<Sharh?>(null);
    final AsyncValue<ApiResponse<UsulHadith>?> usulState =
        usulEnabled && usulAvailable
        ? ref.watch(hadithUsulProvider(HadithRecordId(hadith.hadithId!)))
        : const AsyncData<ApiResponse<UsulHadith>?>(null);

    final sharh = sharhState.hasValue ? sharhState.value : null;
    final usul = usulState.hasValue ? usulState.value?.data : null;
    final loading =
        (sharhEnabled && sharhState.isLoading) ||
        (usulEnabled && usulState.isLoading);
    final sharhFailed =
        sharhEnabled &&
        (sharhState.hasError ||
            (sharhState.hasValue && !hasHadithMetadata(sharh?.sharhText)));
    final usulFailed =
        usulEnabled &&
        (usulState.hasError ||
            (usulState.hasValue && (usul?.sources.isEmpty ?? true)));
    final error = sharhFailed || usulFailed;

    Future<void> export({required bool copy}) async {
      if (isCapturing.value || loading || error) return;
      isCapturing.value = true;
      try {
        await exportHadithShareImage(
          context: context,
          boundaryKey: boundaryKey,
          l10n: l10n,
          primaryColor: theme.colors.primary,
          copyToClipboard: copy,
        );
      } finally {
        if (context.mounted) isCapturing.value = false;
      }
    }

    void update(Set<HadithShareInclude> next) {
      options.value = options.value
          .copyWith(next)
          .constrained(
            hadith: hadith,
            sharhAvailable: sharhAvailable,
            usulAvailable: usulAvailable,
          );
    }

    final busy = isCapturing.value || loading;
    final Widget preview = DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.secondary.withAlpha(60),
        borderRadius: theme.radii.md,
        border: Border.all(color: theme.colors.border),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: ShareCardDragSurface(
              boundaryKey: boundaryKey,
              enabled: !busy && !error,
              child: HadithShareCard(
                boundaryKey: boundaryKey,
                hadith: hadith,
                options: options.value,
                sharh: sharh,
                explanationOrigin: hadith.explanationReference,
                usul: usul,
              ),
            ),
          ),
        ),
      ),
    );

    final selection = FSelectTileGroup<HadithShareInclude>(
      label: Text(l10n.shareIncludeInImage),
      control: .lifted(value: options.value.includes, onChange: update),
      children: [
        if (hasHadithMetadata(hadith.rawi))
          _tile(HadithShareInclude.narrator, l10n.hadithNarrator),
        if (hasHadithMetadata(hadith.mohdith))
          _tile(HadithShareInclude.muhaddith, l10n.hadithMuhaddith),
        if (hasHadithMetadata(hadith.book))
          _tile(HadithShareInclude.source, l10n.hadithSource),
        if (hasHadithMetadata(hadith.numberOrPage))
          _tile(HadithShareInclude.number, l10n.hadithNumberOrPage),
        if (hadithSourceRulings(hadith).isNotEmpty)
          FSelectTile(
            value: HadithShareInclude.grade,
            title: Text(l10n.hadithGradeExplanation),
            enabled: !judgmentRequired,
          ),
        if (hasHadithMetadata(hadith.takhrij))
          _tile(HadithShareInclude.takhrij, l10n.hadithTakhrij),
        if (sharhAvailable) _tile(HadithShareInclude.sharh, l10n.hadithSharh),
        if (usulAvailable)
          _tile(HadithShareInclude.usul, l10n.hadithUsulHadith),
        _tile(HadithShareInclude.appName, l10n.shareAppName),
      ],
    );

    void retryDetails() {
      if (sharhFailed) {
        ref.invalidate(
          hadithSharhProvider(
            SharhId(
              hadith.explanationReference?.id ?? hadith.sharhMetadata!.id,
            ),
          ),
        );
      }
      if (usulFailed) {
        ref.invalidate(hadithUsulProvider(HadithRecordId(hadith.hadithId!)));
      }
    }

    final failedSections = [
      if (sharhFailed) l10n.hadithSharh,
      if (usulFailed) l10n.hadithUsulHadith,
    ];
    final settings = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (judgmentRequired) ...[
          Text(
            l10n.hadithShareJudgmentRequired,
            style: theme.typography.body.sm.copyWith(
              color: theme.colors.foreground,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        selection,
        if (loading) ...[
          const SizedBox(height: AppSpacing.md),
          const Center(child: FCircularProgress.loader()),
        ],
      ],
    );

    return FDialog(
      style: style,
      animation: animation,
      constraints: dialogConstraints(
        context,
        preferredWidth: 920,
        preferredHeight: 620,
        minWidth: 320,
      ),
      builder: (context, dialogStyle) => ForuiDialogLayout(
        style: dialogStyle,
        expandActions: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.hadithShare),
            FButton.icon(
              semanticsLabel: l10n.close,
              onPress: () => Navigator.of(context).pop(),
              variant: .ghost,
              child: const Icon(FLucideIcons.x),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ShareCardDialogLayout(
                preview: preview,
                settings: settings,
              ),
            ),
            if (error) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.md,
                children: [
                  Expanded(
                    child: Text(
                      l10n.hadithShareDetailsFailed(failedSections.join(' • ')),
                      style: theme.typography.body.sm.copyWith(
                        color: theme.colors.foreground,
                        height: 1.6,
                      ),
                    ),
                  ),
                  FButton(
                    variant: .secondary,
                    onPress: retryDetails,
                    child: Text(l10n.retryAction),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          FButton(
            variant: .secondary,
            onPress: isCapturing.value
                ? null
                : () async {
                    try {
                      await Clipboard.setData(
                        ClipboardData(text: hadithShareText(hadith, l10n)),
                      );
                      if (context.mounted) {
                        showFToast(
                          context: context,
                          title: Text(l10n.hadithCopied),
                        );
                      }
                    } on Object {
                      if (context.mounted) {
                        showFToast(
                          context: context,
                          title: Text(l10n.hadithCopyFailed),
                        );
                      }
                    }
                  },
            child: Flexible(
              child: Text(l10n.menuCopyText, textAlign: TextAlign.center),
            ),
          ),
          FButton(
            variant: .secondary,
            onPress: busy || error
                ? null
                : () => unawaited(export(copy: false)),
            child: busy
                ? const FCircularProgress.loader()
                : Flexible(
                    child: Text(
                      l10n.shareSaveImage,
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
          FButton(
            onPress: busy || error ? null : () => unawaited(export(copy: true)),
            child: busy
                ? const FCircularProgress.loader()
                : Flexible(
                    child: Text(
                      l10n.shareCopyImage,
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static FSelectTile<HadithShareInclude> _tile(
    HadithShareInclude value,
    String title,
  ) => FSelectTile(value: value, title: Text(title));
}
