import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/dialog_shell.dart';
import 'package:tawaq/core/widgets/share_card_drag_surface.dart';
import 'package:tawaq/core/widgets/share_card_dialog_layout.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_share_include.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/share/hadith_share_card.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/share/hadith_share_export.dart';
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
  const HadithShareDialog({
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
    final options = useState(HadithShareOptions.defaults(hadith));
    final isCapturing = useState(false);

    final sharhEnabled = options.value.contains(HadithShareInclude.sharh);
    final usulEnabled = options.value.contains(HadithShareInclude.usul);
    final sharhState = sharhEnabled && hadith.hasSharhMetadata
        ? ref.watch(
            hadithDetailProvider(
              HadithDetailKind.sharh,
              hadith.sharhMetadata!.id,
            ),
          )
        : const AsyncData<Object?>(null);
    final usulState =
        usulEnabled && hadith.hasUsulHadith && hadith.hadithId != null
        ? ref.watch(
            hadithDetailProvider(HadithDetailKind.usul, hadith.hadithId!),
          )
        : const AsyncData<Object?>(null);

    final sharh = sharhState.hasValue ? sharhState.value as Sharh? : null;
    final usul = usulState.hasValue ? usulState.value as UsulHadith? : null;
    final loading =
        (sharhEnabled && sharhState.isLoading) ||
        (usulEnabled && usulState.isLoading);
    final error =
        (sharhEnabled && sharhState.hasError) ||
        (usulEnabled && usulState.hasError);

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
        isCapturing.value = false;
      }
    }

    void update(Set<HadithShareInclude> next) {
      options.value = options.value.copyWith(next);
    }

    final busy = isCapturing.value || loading;
    Widget preview = DecoratedBox(
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
                sharh: sharh?.sharhText,
                usul: usul,
              ),
            ),
          ),
        ),
      ),
    );

    Widget settings = FSelectTileGroup<HadithShareInclude>(
      label: Text(l10n.shareIncludeInImage),
      control: .lifted(value: options.value.includes, onChange: update),
      children: [
        _tile(HadithShareInclude.narrator, l10n.hadithNarrator),
        _tile(HadithShareInclude.muhaddith, l10n.hadithMuhaddith),
        _tile(HadithShareInclude.source, l10n.hadithSource),
        _tile(HadithShareInclude.number, l10n.hadithNumberOrPage),
        _tile(HadithShareInclude.grade, l10n.hadithGradeExplanation),
        if ((hadith.takhrij ?? '').trim().isNotEmpty)
          _tile(HadithShareInclude.takhrij, l10n.hadithTakhrij),
        if (hadith.hasSharhMetadata)
          _tile(HadithShareInclude.sharh, l10n.hadithSharh),
        if (hadith.hasUsulHadith && hadith.hadithId != null)
          _tile(HadithShareInclude.usul, l10n.hadithUsulHadith),
        _tile(HadithShareInclude.appName, l10n.shareAppName),
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.hadithShare),
            FButton.icon(
              onPress: () => Navigator.of(context).pop(),
              variant: .ghost,
              child: const Icon(FLucideIcons.x),
            ),
          ],
        ),
        body: ShareCardDialogLayout(preview: preview, settings: settings),
        actions: [
          FButton(
            variant: .secondary,
            onPress: busy || error
                ? null
                : () => unawaited(export(copy: false)),
            child: busy
                ? const FCircularProgress.loader()
                : Text(l10n.shareSaveImage),
          ),
          FButton(
            onPress: busy || error ? null : () => unawaited(export(copy: true)),
            child: busy
                ? const FCircularProgress.loader()
                : Text(l10n.shareCopyImage),
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
