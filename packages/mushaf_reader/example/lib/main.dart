import 'package:flutter/material.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the controller for optimal performance
  await MushafController.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ctrl = PageController();
  final _pageController = TextEditingController();
  final _ayahController = TextEditingController();
  final _surahController = TextEditingController();

  // Preload flag for better UX
  bool _isPreloading = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text(_isPreloading ? 'Quran - Loading...' : 'Quran'),
          backgroundColor: _isPreloading ? Colors.orange : null,
          actions: [
            IconButton(
              onPressed: () => _navigateToPage(-1),
              icon: const Icon(Icons.arrow_back),
            ),
            SizedBox(
              width: 100,
              child: TextField(
                controller: _pageController,
                onSubmitted: (value) => _jumpToPage(value),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Page #',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _navigateToPage(1),
              icon: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _surahController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Surah #',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _ayahController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Ayah #',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                AyahWidget(
                  surah: int.tryParse(_surahController.text) ?? 1,
                  ayah: int.tryParse(_ayahController.text) ?? 1,
                ),
              ],
            ),
            Expanded(
              child: PageView.builder(
                controller: ctrl,
                itemCount: 604,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return SizedBox(
                    height: 1000,
                    width: 500,
                    child: MushafPage(
                      key: ValueKey('page_${index + 1}'),
                      page: index + 1,
                      onTapAyah: (ayahNumber) {
                        debugPrint('Ayah tapped: $ayahNumber');
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ayahController.dispose();
    _surahController.dispose();
    ctrl.dispose();

    // Optional: Clear caches to free memory
    PerformanceUtils.clearCaches();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _preloadInitialPages();
  }

  void _jumpToPage(String value) {
    final page = int.tryParse(value);
    if (page != null && page >= 1 && page <= 604) {
      ctrl.animateToPage(
        page - 1, // PageView is 0-indexed
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _pageController.clear();
    }
  }

  void _navigateToPage(int direction) {
    final currentPage = ctrl.page?.toInt() ?? 0;
    final newPage = currentPage + direction;

    if (newPage >= 0 && newPage < 604) {
      ctrl.animateToPage(
        newPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    // Intelligent preloading: load next/previous pages
    _preloadAdjacentPages(index + 1);
  }

  void _preloadAdjacentPages(int currentPage) {
    final pagesToPreload = <int>[];

    // Preload next 3 and previous 3 pages
    for (int i = -3; i <= 3; i++) {
      final page = currentPage + i;
      if (page >= 1 && page <= 604) {
        pagesToPreload.add(page);
      }
    }

    // Fire-and-forget preloading
    MushafController.instance.preloadPages(pagesToPreload);
  }

  // Preload first few pages for smoother experience
  Future<void> _preloadInitialPages() async {
    setState(() => _isPreloading = true);

    try {
      // Preload first 5 pages for immediate access
      await MushafController.instance.preloadPages([1, 2, 3, 4, 5]);
    } finally {
      setState(() => _isPreloading = false);
    }
  }
}
