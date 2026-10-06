import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/share/hadith_share_dialog.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/share/hadith_share_text.dart';
import 'package:tawaq/theme/theme.dart';

/// Consistent, independent actions after the source text and ruling.
class HadithShareActions extends StatelessWidget {
  const new({required this.hadith, this.favoriteButton, super.key});

  final DetailedHadith hadith;
  final Widget? favoriteButton;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FButton(
          mainAxisSize: MainAxisSize.min,
          size: .sm,
          variant: .ghost,
          prefix: const Icon(FLucideIcons.share2, size: 16),
          semanticsLabel: l10n.hadithShare,
          onPress: () => showHadithShareDialog(context, hadith),
          child: Flexible(child: Text(l10n.hadithShare)),
        ),
        FButton(
          mainAxisSize: MainAxisSize.min,
          size: .sm,
          variant: .ghost,
          prefix: const Icon(FLucideIcons.copy, size: 16),
          semanticsLabel: l10n.menuCopyText,
          onPress: () async {
            try {
              await Clipboard.setData(
                ClipboardData(text: hadithShareText(hadith, l10n)),
              );
              if (context.mounted) {
                showFToast(context: context, title: Text(l10n.hadithCopied));
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
          child: Flexible(child: Text(l10n.menuCopyText)),
        ),
        ?favoriteButton,
      ],
    );
  }
}
