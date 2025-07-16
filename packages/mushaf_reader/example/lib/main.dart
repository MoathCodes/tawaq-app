import 'package:flutter/material.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // It's good practice to pre-cache the first page's assets before the app runs.

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Quran'),
          actions: [
            IconButton(
              onPressed: () {
                final currentPage = ctrl.page?.toInt() ?? 0;
                if (currentPage > 0) {
                  ctrl.animateToPage(
                    currentPage - 1,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeInOut,
                  );
                }
              },
              icon: const Icon(Icons.arrow_back),
            ),
            SizedBox(
              width: 100,
              child: TextField(
                controller: _pageController,
                onSubmitted: (value) {
                  final page = int.tryParse(value);
                  if (page != null && page >= 1 && page <= 604) {
                    ctrl.animateToPage(
                      page - 1, // PageView is 0-indexed
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeInOut,
                    );
                    _pageController.clear();
                  }
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Page #',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                final currentPage = ctrl.page?.toInt() ?? 0;
                if (currentPage < 603) {
                  ctrl.animateToPage(
                    currentPage + 1,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeInOut,
                  );
                }
              },
              icon: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AyahWidget(surah: 114, ayah: 2),
            Expanded(
              child: PageView.builder(
                controller: ctrl,
                itemCount: 604,
                onPageChanged: (index) {
                  // Use the new efficient prefetch system
                },
                itemBuilder: (context, index) {
                  return SizedBox(
                    height: 1000,
                    width: 500,
                    child: MushafPage(
                      key: ValueKey('page_${index + 1}'),
                      page: index + 1,
                      onTap: (ayahNumber) {
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
    ctrl.dispose();
    super.dispose();
  }
}
