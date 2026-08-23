import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/dialog_shell.dart';
import 'package:tawaq/core/widgets/share_card_drag_surface.dart';
import 'package:tawaq/core/widgets/share_card_dialog_layout.dart';
import 'package:tawaq/feature/muslim_fortress/data/repository/fortress_repository.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/models/fortress_share_include.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/share/fortress_share_card.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/share/fortress_share_export.dart';
import 'package:tawaq/theme/theme.dart';

Future<void> showFortressShareDialog(
  BuildContext context,
  FortressDuaItem dua,
) {
  return showFDialog<void>(
    context: context,
    builder: (context, style, animation) =>
        FortressShareDialog(dua: dua, style: style, animation: animation),
  );
}

class FortressShareDialog extends HookConsumerWidget {
  const new({
    required this.dua,
    required this.style,
    this.animation,
    super.key,
  });

  final FortressDuaItem dua;
  final FDialogStyle style;
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = context.theme;
    final boundaryKey = useMemoized(GlobalKey.new);
    final options = useState(
      FortressShareOptions.defaults(
        hasSource: dua.hasSource,
        hasRepetition: dua.targetCount > 1,
      ),
    );
    final commentary = useState<HisnCommentary?>(dua.commentary);
    final loading = useState(false);
    final error = useState<Object?>(null);

    final commentarySelected = options.value.includes.any(
      (value) => const {
        FortressShareInclude.sharh,
        FortressShareInclude.hadith,
        FortressShareInclude.benefit,
      }.contains(value),
    );

    Future<void> loadCommentary() async {
      if (commentary.value != null || loading.value || !dua.hasCommentary) {
        return;
      }
      loading.value = true;
      error.value = null;
      try {
        final repository = await ref.read(fortressRepositoryProvider.future);
        commentary.value = repository.loadCommentaryForContent(dua.contentId);
      } on Object catch (value) {
        error.value = value;
      } finally {
        loading.value = false;
      }
    }

    useEffect(() {
      if (commentarySelected) unawaited(loadCommentary());
      return null;
    }, [commentarySelected]);

    Future<void> export({required bool copy}) async {
      if (loading.value || error.value != null) return;
      await exportFortressShareImage(
        context: context,
        boundaryKey: boundaryKey,
        l10n: l10n,
        primaryColor: theme.colors.primary,
        copyToClipboard: copy,
      );
    }

    void update(Set<FortressShareInclude> next) {
      options.value = options.value.copyWith(next);
      if (next.any(
        (value) => const {
          FortressShareInclude.sharh,
          FortressShareInclude.hadith,
          FortressShareInclude.benefit,
        }.contains(value),
      )) {
        unawaited(loadCommentary());
      }
    }

    final busy = loading.value;
    final disabled = busy || error.value != null;
    final preview = DecoratedBox(
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
              enabled: !disabled,
              child: FortressShareCard(
                boundaryKey: boundaryKey,
                dua: dua,
                options: options.value,
                commentary: commentary.value,
              ),
            ),
          ),
        ),
      ),
    );

    final settings = FSelectTileGroup<FortressShareInclude>(
      label: Text(l10n.shareIncludeInImage),
      control: .lifted(value: options.value.includes, onChange: update),
      children: [
        if (dua.targetCount > 1)
          FSelectTile(
            value: FortressShareInclude.repetition,
            title: Text(l10n.fortressRepetition),
          ),
        if (dua.hasSource)
          FSelectTile(
            value: FortressShareInclude.source,
            title: Text(l10n.fortressSourceReference),
          ),
        if (dua.hasVirtue)
          FSelectTile(
            value: FortressShareInclude.virtue,
            title: Text(l10n.fortressVirtue),
          ),
        if (dua.hasSharh)
          FSelectTile(
            value: FortressShareInclude.sharh,
            title: Text(l10n.fortressSharh),
          ),
        if (dua.hasHadith)
          FSelectTile(
            value: FortressShareInclude.hadith,
            title: Text(l10n.fortressRelatedHadith),
          ),
        if (dua.hasBenefit)
          FSelectTile(
            value: FortressShareInclude.benefit,
            title: Text(l10n.fortressBenefit),
          ),
        FSelectTile(
          value: FortressShareInclude.appName,
          title: Text(l10n.shareAppName),
        ),
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
            Text(l10n.fortressShare),
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
            onPress: disabled ? null : () => unawaited(export(copy: false)),
            child: busy
                ? const FCircularProgress.loader()
                : Text(l10n.shareSaveImage),
          ),
          FButton(
            onPress: disabled ? null : () => unawaited(export(copy: true)),
            child: busy
                ? const FCircularProgress.loader()
                : Text(l10n.shareCopyImage),
          ),
        ],
      ),
    );
  }
}
