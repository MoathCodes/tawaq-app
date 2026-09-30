// Compatibility entry point. Geometry, exports and installation have one owner.
// Prefer ./generate.sh; this forwards the same flags to the Python renderer.
import 'dart:io';

Future<void> main(List<String> arguments) async {
  final toolRoot = File.fromUri(Platform.script).parent.parent;
  final process = await Process.start('python3', [
    '${toolRoot.path}/render.py',
    ...arguments,
  ], mode: ProcessStartMode.inheritStdio);
  exitCode = await process.exitCode;
}
