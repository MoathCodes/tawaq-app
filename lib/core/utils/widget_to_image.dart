import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Captures a [RepaintBoundary] identified by [key] as PNG bytes.
///
/// Waits for the current frame to finish layout/paint before rasterizing.
/// Use a high [pixelRatio] on desktop so exported text stays sharp when shared.
Future<Uint8List?> captureWidgetToPng(
  GlobalKey key, {
  double pixelRatio = 3,
}) async {
  await WidgetsBinding.instance.endOfFrame;

  final boundary =
      key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return null;

  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData?.buffer.asUint8List();
}
