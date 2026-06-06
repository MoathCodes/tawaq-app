import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Copies PNG [bytes] to the system clipboard.
///
/// Returns null on success, or a short localized error message on failure.
Future<String?> copyPngToClipboard(
  Uint8List bytes, {
  required AppLocalizations l10n,
}) async {
  if (!kIsWeb && Platform.isLinux) {
    return _copyPngToClipboardLinux(bytes, l10n: l10n);
  }

  try {
    await Pasteboard.writeImage(bytes);
    return null;
  } on Object catch (error) {
    return l10n.shareImageCopyFailed('$error');
  }
}

Future<String?> _copyPngToClipboardLinux(
  Uint8List bytes, {
  required AppLocalizations l10n,
}) async {
  final command = _linuxClipboardCommand();
  if (command == null) {
    return l10n.shareClipboardInstallHint;
  }

  try {
    final process = await Process.start(command.executable, command.args);
    process.stdin.add(bytes);
    await process.stdin.close();

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      final stderr = await process.stderr
          .transform(const SystemEncoding().decoder)
          .join();
      final detail = stderr.trim().isEmpty
          ? 'exit code $exitCode'
          : stderr.trim();
      return l10n.shareImageCopyFailed(detail);
    }
    return null;
  } on ProcessException catch (error) {
    return l10n.shareImageCopyFailed(error.message);
  }
}

({String executable, List<String> args})? _linuxClipboardCommand() {
  final sessionType = Platform.environment['XDG_SESSION_TYPE'];
  final onWayland = sessionType == 'wayland' ||
      Platform.environment.containsKey('WAYLAND_DISPLAY');

  final executable = onWayland ? 'wl-copy' : 'xclip';
  if (!_commandOnPath(executable)) {
    return null;
  }

  if (onWayland) {
    return (executable: executable, args: ['--type', 'image/png']);
  }
  return (
    executable: executable,
    args: ['-selection', 'clipboard', '-t', 'image/png'],
  );
}

bool _commandOnPath(String command) {
  final result = Process.runSync('which', [command]);
  return result.exitCode == 0;
}
