import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MushafReaderLibrary.ensureInitialized();

  runApp(const MushafExampleApp());
}

class MushafExampleApp extends StatelessWidget {
  const MushafExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mushaf Reader Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B4332),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: const QuranReaderScreen(),
    );
  }
}

class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({super.key});

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  late final MushafReaderController _controller;
  bool _showControls = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      body: Stack(
        children: [
          // The Main Reader
          GestureDetector(
            onTap: _toggleControls,
            child: MushafReader(
              controller: _controller,
              onAyahTap: _handleAyahTap,
              onAyahLongPress: _handleAyahLongPress,
              // Example: Customize text styles using modifiers for easy
              // customization. Use copyWith on the default style to change
              // only what you need while preserving the library defaults.
              // The fontFamily and package are always enforced automatically.
              style: MushafStyle(
                // Easy customization using modifiers - just modify the defaults!
                ayahStyleModifier: (style) =>
                    style.copyWith(color: const Color(0xFF1B4332)),
                // Highlighted ayah with custom background
                activeAyahStyleModifier: (style) => style.copyWith(
                  color: const Color(0xFFFFFFFF),
                  backgroundColor: const Color(0xFF2D6A4F),
                ),
                // Basmalah with custom color
                basmalahStyleModifier: (style) =>
                    style.copyWith(color: const Color(0xFF40916C)),
                // Surah names with custom color
                surahNameStyleModifier: (style) =>
                    style.copyWith(color: const Color(0xFF52B788)),
                // Juz indicators with custom color
                juzStyleModifier: (style) =>
                    style.copyWith(color: const Color(0xFF74C69D)),
                // Page numbers with custom color
                pageNumberStyleModifier: (style) =>
                    style.copyWith(color: const Color(0xFF95D5B2)),
                // Fallback highlight color (used if activeAyahStyle has no backgroundColor)
                highlightColor: const Color.fromARGB(100, 27, 67, 50),
              ),
            ),
          ),

          // Top Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                final pageInfo = _controller.currentPageInfo;

                return AppBar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.95),
                  title: Column(
                    children: [
                      Text(
                        pageInfo?.surahNames.join(' - ') ?? 'The Holy Quran',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Page ${_controller.currentPage} • Juz ${_controller.currentPageInfo?.juzNumber}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.list),
                      onPressed: _showSurahIndex,
                      tooltip: 'Surah Index',
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {},
                    ),
                  ],
                );
              },
            ),
          ),

          // Bottom Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            bottom: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                return Container(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.95),
                  padding: const .symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () =>
                            _controller.jumpToPage(_controller.currentPage + 1),
                        icon: const Icon(Icons.arrow_back_ios),
                      ),
                      Expanded(
                        child: Slider(
                          value: _controller.currentPage.toDouble(),
                          min: 1,
                          max: 604,
                          onChanged: (val) {
                            _controller.jumpToPage(val.toInt());
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _controller.jumpToPage(_controller.currentPage - 1),
                        icon: const Icon(Icons.arrow_forward_ios),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = MushafReaderController();
  }

  void _handleAyahLongPress(AyahInfo info) async {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const .all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(info.reference, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Ayah ${info.ayahId} • Page ${info.page} • Juz ${info.juz}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            // Example: Standalone AyahWidget with custom styling
            // The fontFamily and package are automatically enforced
            // for correct QCF4 font rendering.
            AyahWidget.fromId(
              ayahId: info.ayahId,
              style: const TextStyle(fontSize: 28, color: Color(0xFF1B4332)),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: .spaceEvenly,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.share),
                  tooltip: 'Share',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow),
                  tooltip: 'Play',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.bookmark_border),
                  tooltip: 'Bookmark',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleAyahTap(AyahInfo info) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tapped: ${info.reference}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showSurahIndex() {
    final surahs = _controller.getSurahsSync();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const .all(16.0),
                child: Text(
                  'Surah Index',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: surahs.length,
                  itemBuilder: (context, index) {
                    final surah = surahs[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text('${surah.number}')),
                      title: Text(surah.displayName),
                      subtitle: Text('Page ${surah.startPage ?? "?"}'),
                      onTap: () {
                        Navigator.pop(context);
                        _controller.jumpToSurah(surah.number);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (!_showControls) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }
}
