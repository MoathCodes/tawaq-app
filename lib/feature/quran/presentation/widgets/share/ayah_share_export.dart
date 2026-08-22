import 'package:flutter/material.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/utils/share_card_export.dart';
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
  final loadedAyahs = await Future.wait(ayahIds.map(controller.getAyah));
  final startAyah = loadedAyahs.first;
  final endAyah = loadedAyahs.length == 1 ? startAyah : loadedAyahs.last;
  final startRef = filenameAyahReference(
    ayah: startAyah,
    controller: controller,
  );
  final endRef = filenameAyahReference(ayah: endAyah, controller: controller);
  final safeReference = startRef == endRef ? startRef : '$startRef-$endRef';
  return exportShareCardImage(
    context: context,
    boundaryKey: boundaryKey,
    l10n: l10n,
    primaryColor: primaryColor,
    fileName: 'tawaq-$safeReference.png',
    copyToClipboard: copyToClipboard,
  );
}
