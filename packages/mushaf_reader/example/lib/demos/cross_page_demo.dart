import 'package:example/app_settings.dart';
import 'package:example/demo_scaffold.dart';
import 'package:example/demo_widgets.dart';
import 'package:example/i18n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

class _RangeSlice {
  const _RangeSlice({required this.page, required this.count});

  final int page;
  final int count;
}

class CrossPageRangeDemo extends StatefulWidget {
  const CrossPageRangeDemo({super.key});

  @override
  State<CrossPageRangeDemo> createState() => _CrossPageRangeDemoState();
}

class _CrossPageRangeDemoState extends State<CrossPageRangeDemo> {
  static const _startAyahId = 1;
  static const _endAyahId = 8;

  late final MushafReaderController _controller;
  bool _showSurahHeader = true;
  bool _showBasmalah = true;
  List<_RangeSlice>? _slices;

  @override
  void initState() {
    super.initState();
    _controller = MushafReaderController();
    _loadSlices();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSlices() async {
    final ids = MushafPageRangeLayout.contiguousGlobalIds(
      startAyahId: _startAyahId,
      endAyahId: _endAyahId,
    );
    final counts = <int, int>{};
    final order = <int>[];
    for (final id in ids) {
      final page = await _controller.getPageForAyah(id);
      if (!counts.containsKey(page)) {
        order.add(page);
        counts[page] = 0;
      }
      counts[page] = counts[page]! + 1;
    }
    if (!mounted) return;
    setState(() {
      _slices = [
        for (final page in order)
          _RangeSlice(page: page, count: counts[page]!),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final slices = _slices;

    return DemoScaffold(
      title: t.crossPage.title,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text(t.crossPage.presetLabel),
            subtitle: Text(t.crossPage.presetPages1to2),
          ),
          SwitchListTile(
            title: Text(t.shareCard.showSurahHeader),
            value: _showSurahHeader,
            onChanged: (v) => setState(() => _showSurahHeader = v),
          ),
          SwitchListTile(
            title: Text(t.shareCard.showBasmalah),
            value: _showBasmalah,
            onChanged: (v) => setState(() => _showBasmalah = v),
          ),
          if (slices == null)
            exampleLoadingIndicator(message: t.common.loadingPage)
          else
            ...[
              for (final slice in slices)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    t.crossPage.sliceSummary(
                      page: slice.page,
                      count: slice.count,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              ShareCardPreview(
                child: MushafPageRange.contiguous(
                  startAyahId: _startAyahId,
                  endAyahId: _endAyahId,
                  controller: _controller,
                  showSurahHeader: _showSurahHeader,
                  showBasmalah: _showBasmalah,
                  loadingWidget: exampleLoadingIndicator(
                    message: t.common.loadingPage,
                  ),
                  style: demoMushafStyle(context),
                ),
              ),
            ],
        ],
      ),
    );
  }
}
