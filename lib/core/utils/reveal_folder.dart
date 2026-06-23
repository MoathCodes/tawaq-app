import 'dart:io';

/// Opens [folderPath] in the platform file manager.
///
/// Returns `true` when a reveal command completes successfully.
Future<bool> revealFolderInFileManager(String folderPath) async {
  try {
    final ProcessResult result;
    if (Platform.isLinux) {
      result = await Process.run('xdg-open', [folderPath]);
    } else if (Platform.isMacOS) {
      result = await Process.run('open', [folderPath]);
    } else if (Platform.isWindows) {
      result = await Process.run('explorer', [folderPath]);
    } else {
      return false;
    }
    return result.exitCode == 0;
  } on Object {
    return false;
  }
}
