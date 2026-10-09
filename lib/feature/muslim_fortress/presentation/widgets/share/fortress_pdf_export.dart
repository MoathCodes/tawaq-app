import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf;

/// Owns cancellable PDF decoding, assembly, compression, and disk writing on
/// a worker isolate. Only paths and progress cross the isolate boundary.
class FortressPdfExport {
  final _messages = ReceivePort();
  final _done = Completer<void>();
  Isolate? _worker;
  bool _cancelled = false;

  Future<void> run({
    required List<String> pages,
    required String destination,
    required void Function(int) onProgress,
  }) async {
    // Cancellation may arrive while Isolate.spawn is still completing.
    _done.future.ignore();
    _messages.listen((message) {
      if (_done.isCompleted) return;
      switch (message) {
        case int count:
          onProgress(count);
        case 'ready':
          _done.complete();
        case [String error, String _]:
          _done.completeError(StateError(error));
        case null:
          _done.completeError(StateError('PDF worker exited before finishing'));
      }
    });
    try {
      _worker = await Isolate.spawn(
        _writePdf,
        (pages, destination, _messages.sendPort),
        onError: _messages.sendPort,
        onExit: _messages.sendPort,
        debugName: 'Fortress PDF export',
      );
      if (_cancelled) _worker!.kill(priority: Isolate.immediate);
      await _done.future;
    } finally {
      _worker?.kill(priority: Isolate.immediate);
      _worker = null;
      _messages.close();
    }
  }

  void cancel() {
    _cancelled = true;
    _worker?.kill(priority: Isolate.immediate);
    if (!_done.isCompleted) _done.completeError(const FortressPdfCancelled());
  }
}

class FortressPdfCancelled implements Exception {
  const FortressPdfCancelled();
}

Future<void> _writePdf((List<String>, String, SendPort) request) async {
  final (pages, destination, messages) = request;
  final document = pdf.Document();
  for (final (index, path) in pages.indexed) {
    final image = pdf.MemoryImage(await File(path).readAsBytes());
    document.addPage(
      pdf.Page(
        pageFormat: const PdfPageFormat(432, 540),
        margin: pdf.EdgeInsets.zero,
        build: (_) => pdf.Image(image, fit: pdf.BoxFit.fill),
      ),
    );
    messages.send(index + 1);
  }
  await File(destination).writeAsBytes(await document.save(), flush: true);
  messages.send('ready');
}
