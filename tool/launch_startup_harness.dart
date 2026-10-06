/// Measures the real entry point in an isolated profile-process launch.
/// No synthetic providers, input, network responses, or startup sleeps.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:tawaq/main.dart' as app;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final stopwatch = Stopwatch()..start();
  int? firstFrameMicroseconds;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    firstFrameMicroseconds = stopwatch.elapsedMicroseconds;
  });
  await app.main();
  final deadline = DateTime.now().add(const Duration(seconds: 60));
  while (true) {
    var appMounted = false;
    void visit(Element element) {
      if (element.widget is app.TawaqApp) appMounted = true;
      element.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
    if (appMounted) {
      await WidgetsBinding.instance.endOfFrame;
      final output = Directory(Platform.environment['LAUNCH_REVIEW_DIR']!);
      await File('${output.path}/startup.json').writeAsString(
        jsonEncode({
          'pid': pid,
          'first_framework_frame_us': firstFrameMicroseconds,
          'app_ready_observed_us': stopwatch.elapsedMicroseconds,
          'scope': 'Real main/AppBootstrap with isolated fresh data; excludes process-loader time; 10ms readiness polling; no input or screen-reader claim.',
        }),
        flush: true,
      );
      exit(0);
    }
    if (DateTime.now().isAfter(deadline))
      throw StateError('Real app startup did not become ready');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
