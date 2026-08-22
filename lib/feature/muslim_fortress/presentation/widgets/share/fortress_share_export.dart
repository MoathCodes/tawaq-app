import 'package:flutter/material.dart';
import 'package:tawaq/core/utils/share_card_export.dart';
import 'package:tawaq/l10n/app_localizations.dart';

Future<void> exportFortressShareImage({
  required BuildContext context,
  required GlobalKey boundaryKey,
  required AppLocalizations l10n,
  required Color primaryColor,
  required bool copyToClipboard,
}) => exportShareCardImage(
  context: context,
  boundaryKey: boundaryKey,
  l10n: l10n,
  primaryColor: primaryColor,
  fileName: 'tawaq-fortress-share.png',
  copyToClipboard: copyToClipboard,
);
