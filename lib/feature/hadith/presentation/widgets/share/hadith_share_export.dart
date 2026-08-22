import 'dart:io';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tawaq/core/utils/clipboard_image.dart';
import 'package:tawaq/core/utils/reveal_folder.dart';
import 'package:tawaq/core/utils/widget_to_image.dart';
import 'package:tawaq/l10n/app_localizations.dart';

Future<void> exportHadithShareImage({
  required BuildContext context,
  required GlobalKey boundaryKey,
  required AppLocalizations l10n,
  required Color primaryColor,
  required bool copyToClipboard,
}) async {
  try {
    final bytes = await captureWidgetToPng(boundaryKey);
    if (bytes == null) {
      if (context.mounted) {
        showFToast(
          context: context,
          title: Text(l10n.shareCouldNotCreateImage),
        );
      }
      return;
    }
    if (copyToClipboard) {
      final error = await copyPngToClipboard(bytes, l10n: l10n);
      if (context.mounted) {
        showFToast(
          context: context,
          title: Text(error ?? l10n.shareImageCopied),
        );
      }
      return;
    }
    final directory =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'tawaq-hadith-share.png'));
    await file.writeAsBytes(bytes);
    if (context.mounted) {
      showFToast(
        context: context,
        icon: Icon(FLucideIcons.circleCheck, color: primaryColor),
        title: Text(l10n.shareImageSavedTitle),
        description: Text(p.basename(file.path)),
        suffixBuilder: (toastContext, _) => FButton(
          variant: .secondary,
          onPress: () async {
            final opened = await revealFolderInFileManager(directory.path);
            if (!opened && toastContext.mounted) {
              showFToast(
                context: toastContext,
                title: Text(l10n.openFolderFailed),
              );
            }
          },
          child: Text(l10n.openFolder),
        ),
      );
    }
  } on Object catch (error) {
    if (context.mounted) {
      showFToast(
        context: context,
        title: Text(l10n.shareExportFailed('$error')),
      );
    }
  }
}
