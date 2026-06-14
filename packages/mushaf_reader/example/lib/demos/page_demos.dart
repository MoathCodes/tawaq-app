import 'package:example/app_settings.dart';
import 'package:example/demo_scaffold.dart';
import 'package:example/demo_widgets.dart';
import 'package:example/i18n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

class SinglePageDemo extends StatefulWidget {
  const SinglePageDemo({super.key});

  @override
  State<SinglePageDemo> createState() => _SinglePageDemoState();
}

class _SinglePageDemoState extends State<SinglePageDemo> {
  late final MushafReaderController _controller;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _controller = MushafReaderController(initialPage: _page);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: t.common.pageLabel(page: _page),
      body: Column(
        children: [
          PageNavigatorControls(
            page: _page,
            onPageChanged: (page) {
              setState(() => _page = page);
              _controller.jumpToPage(page);
            },
          ),
          Expanded(
            child: MushafPage(
              page: _page,
              controller: _controller,
              style: demoMushafStyle(context),
              loadingWidget: exampleLoadingIndicator(
                message: t.common.loadingPage,
              ),
              onAyahIdTap: (ayahId) async {
                final ayah = await _controller.getAyah(ayahId);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      t.common.tappedAyah(reference: ayah.reference),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PageRangeShareDemo extends StatefulWidget {
  const PageRangeShareDemo({super.key});

  @override
  State<PageRangeShareDemo> createState() => _PageRangeShareDemoState();
}

class _PageRangeShareDemoState extends State<PageRangeShareDemo> {
  late final MushafReaderController _controller;
  int _page = 1;
  QuranPage? _pageData;
  Object? _loadError;
  bool _loading = true;
  bool _showSurahHeader = true;
  bool _showBasmalah = true;
  int _rangeEndIndex = 2;

  @override
  void initState() {
    super.initState();
    _controller = MushafReaderController(initialPage: _page);
    _loadPage();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPage() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final page = await _controller.getPage(_page);
      if (!mounted) return;
      setState(() {
        _pageData = page;
        _loading = false;
        final ayahCount = MushafPageRangeLayout.orderedAyahIdsOnPage(page).length;
        if (ayahCount > 0) {
          _rangeEndIndex = _rangeEndIndex.clamp(0, ayahCount - 1);
        }
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  void _onPageChanged(int page) {
    setState(() => _page = page);
    _controller.jumpToPage(page);
    _loadPage();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _pageData == null) {
      return exampleLoadingScaffold(title: t.shareCard.title);
    }
    if (_loadError != null) {
      return exampleErrorScaffold(
        title: t.shareCard.title,
        onRetry: _loadPage,
      );
    }

    final page = _pageData!;
    final ayahIds = MushafPageRangeLayout.orderedAyahIdsOnPage(page);
    final endIndex = ayahIds.isEmpty
        ? 0
        : _rangeEndIndex.clamp(0, ayahIds.length - 1);
    final selectedIds = ayahIds.isEmpty
        ? <int>[]
        : ayahIds.sublist(0, endIndex + 1);
    final basmalahPossible = selectedIds.isNotEmpty &&
        MushafPageRangeLayout.basmalahPossible(page, selectedIds);

    return DemoScaffold(
      title: t.shareCard.title,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PageNavigatorControls(
            page: _page,
            onPageChanged: _onPageChanged,
          ),
          SwitchListTile(
            title: Text(t.shareCard.showSurahHeader),
            value: _showSurahHeader,
            onChanged: (v) => setState(() => _showSurahHeader = v),
          ),
          SwitchListTile(
            title: Text(t.shareCard.showBasmalah),
            subtitle: basmalahPossible
                ? null
                : Text(t.shareCard.basmalahUnavailable),
            value: _showBasmalah && basmalahPossible,
            onChanged: basmalahPossible
                ? (v) => setState(() => _showBasmalah = v)
                : null,
          ),
          if (selectedIds.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AyahReferenceLabel(
                    ayahId: selectedIds.last,
                    controller: _controller,
                    builder: (context, reference) => Text(
                      t.shareCard.rangeEnd(reference: reference),
                    ),
                  ),
                  Slider(
                    value: endIndex.toDouble(),
                    min: 0,
                    max: (ayahIds.length - 1).toDouble(),
                    divisions: ayahIds.length - 1,
                    label: '${selectedIds.last}',
                    onChanged: (v) =>
                        setState(() => _rangeEndIndex = v.round()),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          if (selectedIds.isNotEmpty)
            ShareCardPreview(
              child: MushafPageRange.onPage(
                page: page.pageNumber,
                startAyahId: selectedIds.first,
                endAyahId: selectedIds.last,
                pageData: page,
                showSurahHeader: _showSurahHeader,
                showBasmalah: _showBasmalah,
                loadingWidget: exampleLoadingIndicator(
                  message: t.common.loadingPage,
                ),
                style: demoMushafStyle(context),
              ),
            ),
        ],
      ),
    );
  }
}
