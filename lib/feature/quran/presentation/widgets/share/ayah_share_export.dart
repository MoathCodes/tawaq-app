import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tawaq/core/utils/clipboard_image.dart';
import 'package:tawaq/core/utils/reveal_folder.dart';
import 'package:tawaq/core/utils/widget_to_image.dart';
import 'package:tawaq/feature/quran/presentation/extensions/ayah_reference_formatter.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Exports a rendered ayah share card as a PNG file or clipboard image.
Future<void> exportAyahShareImage({
  required BuildContext context,
  required GlobalKey boundaryKey,
  required MushafReaderController controller,
  required List<int> ayahIds,
  required AppLocalizations l10n,
  required Color primaryColor,
  required bool copyToClipboard,
}) async {
  try {
    final loadedAyahs = await Future.wait(ayahIds.map(controller.getAyah));
    await WidgetsBinding.instance.endOfFrame;
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
          title: Text(
            error ?? l10n.shareImageCopied,
          ),
        );
      }
      return;
    }

    final downloads = await getDownloadsDirectory();
    final directory = downloads ?? await getApplicationDocumentsDirectory();
    final startAyah = loadedAyahs.first;
    final endAyah = loadedAyahs.length == 1 ? startAyah : loadedAyahs.last;
    final startRef = filenameAyahReference(
      ayah: startAyah,
      controller: controller,
    );
    final endRef = filenameAyahReference(
      ayah: endAyah,
      controller: controller,
    );
    final safeReference = startRef == endRef
        ? startRef
        : '$startRef-$endRef';
    final file = File(
      p.join(directory.path, 'tawaq-$safeReference.png'),
    );
    await file.writeAsBytes(bytes);
    if (context.mounted) {
      final folderPath = directory.path;
      final fileName = p.basename(file.path);
      showFToast(
        context: context,
        icon: Icon(FLucideIcons.circleCheck, color: primaryColor),
        title: Text(l10n.shareImageSavedTitle),
        description: Text(fileName),
        suffixBuilder: (toastContext, entry) => FButton(
          variant: .secondary,
          onPress: () async {
            final opened = await revealFolderInFileManager(folderPath);
            if (!opened && toastContext.mounted) {
              showFToast(
                context: toastContext,
                variant: .destructive,
                icon: const Icon(FLucideIcons.triangleAlert),
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
