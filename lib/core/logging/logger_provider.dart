import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logger_provider.g.dart';

PrettyPrinter _printer() => PrettyPrinter(
  methodCount: 0,
  errorMethodCount: 5,
  lineLength: 80,
  // Absolute date+time so log lines can be correlated with prayer times.
  dateTimeFormat: DateTimeFormat.dateAndTime,
  // No ANSI colours: the same output is shared with the on-disk log file.
  colors: false,
);

/// Global Logger instance for the application.
///
/// Starts as console-only with the default [DevelopmentFilter] (debug builds
/// only). Call [initFileLogging] once at startup to swap in a build that also
/// writes to a persistent file and emits in release — without it, release
/// builds omit every log. See [logFilePath] for where the file lives.
Logger logger = Logger(printer: _printer());

/// Absolute path of the persistent log file, set by [initFileLogging].
///
/// Resolves to `<app-support>/logs/tawaq.log`, e.g. on Linux
/// `~/.local/share/<app>/logs/tawaq.log`. Null until initialised (or if init
/// failed).
String? logFilePath;

/// Wires the global [logger] to also write to a file and to emit in release.
///
/// Call once early in `main` (after the Flutter binding is initialised). The
/// file is truncated on each launch so it stays bounded and reflects the
/// current session — copy it elsewhere if you need history. Any failure is
/// swallowed so logging never blocks startup; the console logger stays put.
Future<void> initFileLogging() async {
  try {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/logs/tawaq.log');
    await file.parent.create(recursive: true);

    logger = Logger(
      // ProductionFilter emits regardless of build mode (gated by [level]),
      // so the file captures logs in release where DevelopmentFilter would not.
      // Keep verbose debug only in kDebugMode; release stays at info+.
      filter: ProductionFilter(),
      level: kDebugMode ? Level.debug : Level.info,
      printer: _printer(),
      output: MultiOutput([
        ConsoleOutput(),
        FileOutput(file: file, overrideExisting: true),
      ]),
    );
    logFilePath = file.path;
    logger.i('File logging initialised at ${file.path}');
  } on Object catch (error, stack) {
    // Keep the console logger; never let logging setup crash startup.
    logger.e(
      'Failed to initialise file logging',
      error: error,
      stackTrace: stack,
    );
  }
}

/// Exposes the shared [Logger] instance to Riverpod widgets and services.
@riverpod
Logger loggerNotifier(Ref ref) {
  return logger;
}
