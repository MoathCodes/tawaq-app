import 'package:example/app_settings.dart';
import 'package:example/demo_scaffold.dart';
import 'package:example/i18n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

class FullReaderDemo extends StatefulWidget {
  const FullReaderDemo({super.key});

  @override
  State<FullReaderDemo> createState() => _FullReaderDemoState();
}

class _FullReaderDemoState extends State<FullReaderDemo> {
  late final MushafReaderController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MushafReaderController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: t.demos.mushafReader.title,
      body: MushafReader(
        controller: _controller,
        style: demoMushafStyle(context),
        loadingWidget: const CircularProgressIndicator(),
        onAyahTap: (ayah) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.common.tappedAyah(reference: ayah.reference)),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}

class TwoPageReaderDemo extends StatefulWidget {
  const TwoPageReaderDemo({super.key});

  @override
  State<TwoPageReaderDemo> createState() => _TwoPageReaderDemoState();
}

class _TwoPageReaderDemoState extends State<TwoPageReaderDemo> {
  late final MushafReaderController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MushafReaderController();
    _controller.pagesPerViewport = 2;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: t.demos.twoPageSpread.title,
      body: Column(
        children: [
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final left = _controller.currentPage;
              final right = (left + 1).clamp(1, MushafConstants.pageCount);
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  t.common.pagesSpread(left: left, right: right),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              );
            },
          ),
          Expanded(
            child: MushafReader(
              controller: _controller,
              pagesPerViewport: 2,
              style: demoMushafStyle(context),
              loadingWidget: const CircularProgressIndicator(),
              onAyahTap: (ayah) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      t.common.tappedAyah(reference: ayah.reference),
                    ),
                  ),
                );
              },
              onSpreadChanged: (info) {
                debugPrint(
                  'Spread: ${info.$1.pageNumber}, ${info.$2?.pageNumber}',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
