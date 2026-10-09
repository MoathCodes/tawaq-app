/// Native QA of production Fortress widgets against bundled source content.
/// Data and exports stay under FORTRESS_REVIEW_DIR; no user settings are loaded.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:forui/forui.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf;
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/share/fortress_pdf_export.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:tawaq/feature/muslim_fortress/data/repository/fortress_repository.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/screens/muslim_fortress_screen.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/muslim_fortress_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/fortress_screen_settings_provider.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_screen_state.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/browse/fortress_category_detail.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_category_row.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_dua_content.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_dua_insights.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_study_panel.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_focus_reading.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/share/fortress_booklet_plan.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/models/fortress_share_include.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_ui_models.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _ReviewRepository extends FortressRepository {
  _ReviewRepository(super.client);
  bool failDetails = false;
  @override
  HisnCommentary? loadCommentaryForContent(int id) {
    if (failDetails) throw StateError('Controlled QA detail-load failure');
    return super.loadCommentaryForContent(id);
  }
}

class _Settings extends QuranScreenSettingsNotifier {
  @override
  Future<QuranScreenState> build() async => QuranScreenState.initial();
}

class _FortressSettings extends FortressScreenSettingsNotifier {
  @override
  Future<FortressScreenState> build() async => FortressScreenState.initial();
}

class _Paths extends PathProviderPlatform {
  _Paths(this.root);
  final String root;
  @override
  Future<String?> getDownloadsPath() async => root;
  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

final capture = GlobalKey();
final previewExpanded = ValueNotifier(true);
bool reviewFullBrowse = true;
typedef Configuration = ({
  Size size,
  String locale,
  ThemeMode mode,
  AppPalette palette,
  int index,
  double scale,
  int chapterId,
  bool browse,
});
final config = ValueNotifier<Configuration>((
  size: const Size(1200, 850),
  locale: 'ar',
  mode: ThemeMode.dark,
  palette: AppPalette.manuscript,
  index: 0,
  scale: 1,
  chapterId: 0,
  browse: false,
));
final errors = <String>[];
final timings = <FrameTiming>[];
void visit(Element element, void Function(Element) action) {
  action(element);
  element.visitChildren((e) => visit(e, action));
}

T? widgetWhere<T extends Widget>(bool Function(T) predicate) {
  T? result;
  visit(capture.currentContext! as Element, (e) {
    if (e.widget is T && predicate(e.widget as T)) result = e.widget as T;
  });
  return result;
}

Future<void> press(String label) async {
  FButton? button;
  visit(capture.currentContext! as Element, (e) {
    if (e.widget is! FButton) return;
    var matches = false;
    visit(e, (child) {
      if (child.widget is Text && (child.widget as Text).data == label)
        matches = true;
    });
    if (matches) button = e.widget as FButton;
  });
  if (button?.onPress == null)
    throw StateError('Enabled button not found: $label');
  button!.onPress!();
  await Future<void>.delayed(const Duration(milliseconds: 1200));
}

Future<void> tapText(String label) async {
  FTabs? tabs;
  var selected = -1;
  visit(capture.currentContext! as Element, (e) {
    if (e.widget is! FTabs) return;
    final candidate = e.widget as FTabs;
    for (final (index, entry) in candidate.children.indexed) {
      if (entry.label is Text && (entry.label as Text).data == label) {
        tabs = candidate;
        selected = index;
      }
    }
  });
  if (tabs == null) throw StateError('Tab not found: $label');
  // The production lifted Forui callback; no duplicate QA business rules.
  (tabs!.control as dynamic).onChange(selected);
  await Future<void>.delayed(const Duration(milliseconds: 700));
}

Future<void> snap(Directory output, String name) async {
  await WidgetsBinding.instance.endOfFrame;
  final boundary =
      capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  await File('${output.path}/$name.png')
      .writeAsBytes(data!.buffer.asUint8List());
  image.dispose();
  stdout.writeln('Captured $name');
}

Future<void> main() async {
  enableFlutterDriverExtension();
  final output = await Directory(
    Platform.environment['FORTRESS_REVIEW_DIR'] ?? '/tmp/tawaq-fortress-review',
  ).create(recursive: true);
  PathProviderPlatform.instance = _Paths(output.path);
  await MushafReaderLibrary.ensureInitialized(subDirectory: 'mushaf-review');
  final client = await HisnClient.openFromDirectory(
    '${Directory.current.path}/packages/hisn_elmoslem/assets/database',
  );
  final repository = _ReviewRepository(client);
  final chapter = repository.loadChapters().firstWhere(
    (c) => c.title.contains(HisnFeaturedTitles.morning),
  );
  final items = repository.loadDuas(chapter.chapterId);
  final short = items.indexWhere(
    (item) =>
        !item.isQuranicPassage &&
        item.text.length < 70 &&
        item.targetCount >= 33,
  );
  final long = items.indexWhere(
    (item) => item.hasSharh && !item.isQuranicPassage,
  );
  config.value = (
    size: const Size(1200, 850),
    locale: 'ar',
    mode: ThemeMode.dark,
    palette: AppPalette.manuscript,
    index: short,
    scale: 1,
    chapterId: chapter.chapterId,
    browse: false,
  );
  final errorHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    errors.add(details.exceptionAsString());
    errorHandler?.call(details);
  };
  WidgetsBinding.instance.addTimingsCallback(timings.addAll);
  final container = ProviderContainer(
    overrides: [
      fortressRepositoryProvider.overrideWith((ref) async => repository),
      quranScreenSettingsProvider.overrideWith(_Settings.new),
      fortressScreenSettingsProvider.overrideWith(_FortressSettings.new),
      fortressRecommendedCategoriesProvider.overrideWith((ref) => []),
    ],
  );
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: ValueListenableBuilder(
        valueListenable: config,
        builder: (context, value, _) {
          final activeChapter = repository.loadChapters().firstWhere(
            (c) => c.chapterId == value.chapterId,
          );
          final activeItems = repository.loadDuas(value.chapterId);
          final theme = buildAppTheme(
            palette: value.palette,
            themeMode: value.mode,
            touch: false,
            textScale: 1,
          );
          return OverflowBox(
            minWidth: value.size.width,
            maxWidth: value.size.width,
            minHeight: value.size.height,
            maxHeight: value.size.height,
            child: RepaintBoundary(
              key: capture,
              child: FTheme(
                data: theme,
                child: FToaster(
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: theme.toApproximateMaterialTheme(),
                    locale: Locale(value.locale),
                    localizationsDelegates: appLocalizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    builder: (context, child) => MaterialUiCompatibilityBridge(
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          size: value.size,
                          textScaler: TextScaler.linear(value.scale),
                        ),
                        child: child!,
                      ),
                    ),
                    home:
                        value.browse &&
                            reviewFullBrowse &&
                            const bool.fromEnvironment('RTL_ONLY')
                        ? Scaffold(
                            body: MuslimFortressScreen(key: ValueKey(value)),
                          )
                        : value.browse
                        ? FortressStudyHost(
                            key: ValueKey(value),
                            child: Scaffold(
                              body: Row(
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.all(24),
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 840,
                                          ),
                                          child: ValueListenableBuilder(
                                            valueListenable: previewExpanded,
                                            builder: (_, expanded, _) =>
                                                FortressDuaPreviewCard(
                                                  index: value.index,
                                                  dua: activeItems[value.index],
                                                  isExpanded: expanded,
                                                  onToggleExpanded: () =>
                                                      previewExpanded.value =
                                                          !previewExpanded
                                                              .value,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 240,
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        children: [
                                          for (final c
                                              in repository.loadChapters().take(
                                                4,
                                              )) ...[
                                            FortressCategoryRow(
                                              category: c,
                                              l10n: lookupAppLocalizations(
                                                Locale(value.locale),
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : FortressFocusReadingSurface(
                            key: ValueKey(value),
                            category: activeChapter,
                            duas: activeItems,
                            initialIndex: value.index,
                            onExit: () {},
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
  await Future<void>.delayed(const Duration(seconds: 3));
  if (const bool.fromEnvironment('CAPTURE_DETAIL_ERROR')) {
    repository.failDetails = true;
    final l10n = lookupAppLocalizations(const Locale('ar'));
    await press(l10n.fortressShare);
    await selectIncludes({...FortressShareInclude.values});
    await Future<void>.delayed(const Duration(seconds: 2));
    await snap(output, 'detail-load-error');
    exit(errors.isEmpty ? 0 : 1);
  }
  if (const bool.fromEnvironment('RTL_ONLY')) {
    await rtlReview(output, repository, container, chapter.chapterId, short);
    exit(errors.isEmpty ? 0 : 1);
  }
  if (const bool.fromEnvironment('FOLLOWUP_ONLY')) {
    await followup(output, repository);
    exit(errors.isEmpty ? 0 : 1);
  }
  if (const bool.fromEnvironment('CORRECTIONS_ONLY')) {
    await corrections(output, repository, chapter.chapterId, short, long);
    exit(errors.isEmpty ? 0 : 1);
  }
  await snap(output, 'desktop-focus');
  WidgetsBinding.instance.handleAppLifecycleStateChanged(
    AppLifecycleState.resumed,
  );
  await WidgetsBinding.instance.endOfFrame;
  timings.clear();
  for (var i = 0; i < 40; i++) {
    widgetWhere<FTappable>((w) => w.key == const ValueKey('fortress-counter'))!
        .onPress!();
    await Future<void>.delayed(const Duration(milliseconds: 160));
  }
  await Future<void>.delayed(const Duration(milliseconds: 400));
  final frameData = timings
      .map(
        (t) => {
          'build_us': t.buildDuration.inMicroseconds,
          'raster_us': t.rasterDuration.inMicroseconds,
        },
      )
      .toList();
  await File('${output.path}/count-profile.json')
      .writeAsString(jsonEncode(frameData));
  await snap(output, 'desktop-counted');
  config.value = (
    size: const Size(1200, 850),
    locale: 'ar',
    mode: ThemeMode.dark,
    palette: AppPalette.manuscript,
    index: long,
    scale: 1,
    chapterId: chapter.chapterId,
    browse: false,
  );
  await Future<void>.delayed(const Duration(seconds: 2));
  await press(lookupAppLocalizations(const Locale('ar')).fortressSharh);
  await snap(output, 'desktop-study');
  config.value = (
    size: const Size(800, 900),
    locale: 'en',
    mode: ThemeMode.light,
    palette: AppPalette.sage,
    index: long,
    scale: 1,
    chapterId: chapter.chapterId,
    browse: false,
  );
  await Future<void>.delayed(const Duration(seconds: 2));
  await snap(output, 'tablet-focus');
  config.value = (
    size: const Size(390, 844),
    locale: 'ar',
    mode: ThemeMode.dark,
    palette: AppPalette.manuscript,
    index: short,
    scale: 1,
    chapterId: chapter.chapterId,
    browse: false,
  );
  await Future<void>.delayed(const Duration(seconds: 2));
  await snap(output, 'phone-focus');
  await press(lookupAppLocalizations(const Locale('ar')).fortressSharh);
  await snap(output, 'phone-study');
  config.value = (
    size: const Size(390, 844),
    locale: 'en',
    mode: ThemeMode.light,
    palette: AppPalette.manuscript,
    index: long,
    scale: 2,
    chapterId: chapter.chapterId,
    browse: false,
  );
  await Future<void>.delayed(const Duration(seconds: 2));
  await snap(output, 'phone-large-text');
  config.value = (
    size: const Size(1200, 850),
    locale: 'ar',
    mode: ThemeMode.dark,
    palette: AppPalette.manuscript,
    index: short,
    scale: 1,
    chapterId: chapter.chapterId,
    browse: false,
  );
  await Future<void>.delayed(const Duration(seconds: 2));
  await press(lookupAppLocalizations(const Locale('ar')).fortressShare);
  // Scope tabs and inclusion tiles invoke the production lifted controls.
  final l10n = lookupAppLocalizations(const Locale('ar'));
  visit(capture.currentContext! as Element, (e) {
    if (e.widget is FTabs) {
      var matched = false;
      visit(e, (c) {
        if (c.widget is Text &&
            (c.widget as Text).data == l10n.fortressEntireChapter)
          matched = true;
      });
      if (matched) stdout.writeln("Scope tabs found");
    }
  });
  await tapText(l10n.fortressEntireChapter);
  await Future<void>.delayed(const Duration(seconds: 3));
  await snap(output, 'chapter-booklet');
  final preview = widgetWhere<FortressBookletPreview>((_) => true)!;
  await File('${output.path}/booklet-first.png')
      .writeAsBytes(await preview.plan.png(0));
  await File('${output.path}/booklet-last.png')
      .writeAsBytes(await preview.plan.png(preview.plan.pages.length - 1));
  await press(
    preview.plan.pages.length == 1
        ? l10n.shareSaveImage
        : l10n.fortressSavePages,
  );
  await Future<void>.delayed(const Duration(seconds: 5));
  await tapText('PDF');
  await press(l10n.fortressSavePdf);
  await Future<void>.delayed(const Duration(seconds: 5));
  await selectIncludes({...FortressShareInclude.values});
  for (
    var attempt = 0;
    attempt < 120 && widgetWhere<FortressBookletPreview>((_) => true) == null;
    attempt++
  ) {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  await snap(output, 'chapter-study-booklet');
  final studyPreview = widgetWhere<FortressBookletPreview>((_) => true)!;
  await File('${output.path}/study-last.png').writeAsBytes(
    await studyPreview.plan.png(studyPreview.plan.pages.length - 1),
  );
  NavigatorState? navigation;
  visit(capture.currentContext! as Element, (e) {
    if (e is StatefulElement && e.state is NavigatorState)
      navigation = e.state as NavigatorState;
  });
  navigation!.pop();
  await Future<void>.delayed(const Duration(seconds: 1));
  await File('${output.path}/profile.json').writeAsString(
    jsonEncode({
      'count_frames': frameData,
      'reading_pages': preview.plan.pages.length,
      'study_pages': studyPreview.plan.pages.length,
      'errors': errors,
    }),
  );
  // Native render frames proving the final count, dwell, and next transition.
  final frames = await Directory('${output.path}/frames').create();
  config.value = (
    size: const Size(1200, 850),
    locale: 'ar',
    mode: ThemeMode.dark,
    palette: AppPalette.manuscript,
    index: short,
    scale: 1.000002,
    chapterId: chapter.chapterId,
    browse: false,
  );
  await Future<void>.delayed(const Duration(seconds: 2));
  WidgetsBinding.instance.handleAppLifecycleStateChanged(
    AppLifecycleState.resumed,
  );
  await WidgetsBinding.instance.endOfFrame;
  for (var i = 0; i < items[short].targetCount - 1; i++) {
    widgetWhere<FTappable>((w) => w.key == const ValueKey('fortress-counter'))!
        .onPress!();
  }
  await Future<void>.delayed(const Duration(milliseconds: 300));
  for (var frame = 0; frame < 36; frame++) {
    if (frame == 6)
      widgetWhere<FTappable>(
        (w) => w.key == const ValueKey('fortress-counter'),
      )!.onPress!();
    await snap(frames, frame.toString().padLeft(3, '0'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  await File('${output.path}/report.json').writeAsString(
    jsonEncode({
      'source': 'Bundled Hisn databases; production Flutter widgets; fixed native render viewport',
      'chapter': chapter.chapterId,
      'short_index': short,
      'long_index': long,
      'reading_pages': preview.plan.pages.length,
      'study_pages': studyPreview.plan.pages.length,
      'errors': errors,
      'count_frames': frameData,
    }),
  );
  stdout.writeln('Native verification complete: ${errors.length} errors');
  if (!const bool.fromEnvironment('KEEP_OPEN')) exit(errors.isEmpty ? 0 : 1);
}

Future<void> selectIncludes(Set<FortressShareInclude> includes) async {
  final tiles = widgetWhere<FSelectTileGroup<FortressShareInclude>>(
    (_) => true,
  )!;
  (tiles.control as dynamic).onChange(includes);
  await Future<void>.delayed(const Duration(milliseconds: 700));
}

Future<void> pressIcon(String label) async {
  final button = widgetWhere<FButton>((w) => w.semanticsLabel == label);
  if (button?.onPress == null) throw StateError('Enabled icon missing: $label');
  button!.onPress!();
  await Future<void>.delayed(const Duration(milliseconds: 800));
}

// Sends actual pointer events through the native widget hit-test tree.
Future<void> tapProductionWidget<T extends Widget>() async {
  Element? target;
  visit(capture.currentContext! as Element, (e) {
    if (e.widget is T) target ??= e;
  });
  final box = target!.findRenderObject()! as RenderBox;
  final point = box.localToGlobal(
    Offset(box.size.width / 2, T == FModalBarrier ? box.size.height / 2 : 10),
  );
  WidgetsBinding.instance.handleAppLifecycleStateChanged(
    AppLifecycleState.resumed,
  );
  GestureBinding.instance.handlePointerEvent(
    PointerDownEvent(
      pointer: 100,
      position: point,
      buttons: kPrimaryButton,
      kind: ui.PointerDeviceKind.mouse,
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 70));
  GestureBinding.instance.handlePointerEvent(
    PointerUpEvent(
      pointer: 100,
      position: point,
      kind: ui.PointerDeviceKind.mouse,
    ),
  );
  await WidgetsBinding.instance.endOfFrame;
}

Future<void> corrections(
  Directory output,
  FortressRepository repository,
  int morning,
  int short,
  int long,
) async {
  final l10n = lookupAppLocalizations(const Locale('ar'));
  Future<void> scene(
    int chapterId,
    int index, {
    bool browse = false,
    String locale = 'ar',
    ThemeMode mode = ThemeMode.dark,
    Size size = const Size(1200, 850),
    double scale = 1,
  }) async {
    config.value = (
      size: size,
      locale: locale,
      mode: mode,
      palette: AppPalette.manuscript,
      index: index,
      scale: scale,
      chapterId: chapterId,
      browse: browse,
    );
    await Future<void>.delayed(const Duration(seconds: 2));
    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> expectTap<T extends Widget>(String name) async {
    final before = widgetWhere<FTappable>(
      (w) => w.key == const ValueKey('fortress-counter'),
    )!;
    if (before.onPress == null)
      throw StateError('Counter initially disabled: $name');
    // Counter semantic value is read from production, never emulated here.
    String? value() {
      Element? counter;
      visit(capture.currentContext! as Element, (e) {
        if (e.widget.key == const ValueKey('fortress-counter')) counter = e;
      });
      String? result;
      counter!.visitAncestorElements((e) {
        if (e.widget is Semantics &&
            (e.widget as Semantics).properties.liveRegion == true) {
          result = (e.widget as Semantics).properties.label;
          return false;
        }
        return true;
      });
      return result;
    }

    final prior = value();
    await tapProductionWidget<T>();
    if (value() == prior)
      throw StateError('Pointer tap did not count: $name ($prior)');
    stdout.writeln('Pointer tap counted: $name $prior -> ${value()}');
    await snap(output, name);
  }

  await snap(output, 'desktop-focus');
  await press(l10n.fortressSharh);
  await snap(output, 'desktop-side-sheet');
  await expectTap<FortressDhikrText>('count-with-details');
  await scene(morning, 1);
  await expectTap<AyahWidget>('ayah-tap');
  await scene(morning, 2);
  await expectTap<MushafPageRange>('mushaf-tap');
  final travel = repository.loadChapters().firstWhere(
    (c) => repository.loadDuas(c.chapterId).any((d) => d.contentId == 336),
  );
  final travelIndex = repository
      .loadDuas(travel.chapterId)
      .indexWhere((d) => d.contentId == 336);
  await scene(travel.chapterId, travelIndex);
  await snap(output, 'quoted-ayah-prose');
  await scene(morning, 1, browse: true);
  await snap(output, 'expanded-reading-card');
  await press(l10n.fortressSharh);
  await snap(output, 'browse-persistent-sheet');
  await scene(
    morning,
    long,
    locale: 'en',
    mode: ThemeMode.light,
    size: const Size(800, 900),
  );
  await press(lookupAppLocalizations(const Locale('en')).fortressSharh);
  await snap(output, 'compact-side-sheet');
  await scene(
    morning,
    long,
    locale: 'en',
    mode: ThemeMode.light,
    size: const Size(390, 844),
    scale: 2,
  );
  await snap(output, 'large-text-focus');
  final two = repository.loadChapters().firstWhere((c) {
    final ds = repository.loadDuas(c.chapterId);
    return ds.length == 2 &&
        ds.every((d) => d.targetCount == 1 && !d.isQuranicPassage);
  });
  await scene(two.chapterId, 0);
  for (var i = 0; i < 2; i++) {
    // An off-workspace native QA window may receive inactive notifications.
    // Resume the real observer before each completion boundary.
    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.inactive,
    );
    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await WidgetsBinding.instance.endOfFrame;
    widgetWhere<FTappable>((w) => w.key == const ValueKey('fortress-counter'))!
        .onPress!();
    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.inactive,
    );
    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await Future<void>.delayed(const Duration(milliseconds: 900));
  }
  await snap(output, 'desktop-completed');
  await press(l10n.fortressReadAgain);
  for (var i = 0; i < 2; i++)
    await pressIcon(i == 1 ? l10n.fortressFinish : l10n.next);
  await snap(output, 'desktop-unfinished');
  await scene(morning, short);
  await press(l10n.fortressShare);
  await tapText(l10n.fortressEntireChapter);
  await Future<void>.delayed(const Duration(seconds: 3));
  await snap(output, 'share-inclusions');
  // Close the actual production dialog.
  NavigatorState? navigation;
  visit(capture.currentContext! as Element, (e) {
    if (e is StatefulElement && e.state is NavigatorState)
      navigation = e.state as NavigatorState;
  });
  navigation!.pop();
  await Future<void>.delayed(const Duration(milliseconds: 500));
  await scene(two.chapterId, 0);
  final frames = await Directory('${output.path}/frames')
      .create(recursive: true);
  final frameTimes = <int>[];
  final clock = Stopwatch()..start();
  for (var frame = 0; frame < 16; frame++) {
    if (frame == 2)
      widgetWhere<FTappable>(
        (w) => w.key == const ValueKey('fortress-counter'),
      )!.onPress!();
    frameTimes.add(clock.elapsedMicroseconds);
    await snap(frames, frame.toString().padLeft(3, '0'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  await File('${output.path}/corrections-report.json').writeAsString(
    jsonEncode({
      'source': 'Production native Flutter widgets, bundled Hisn content; pointer events hit actual widget render bounds',
      'morning': morning,
      'travel': travel.chapterId,
      'completion': two.chapterId,
      'frame_us': frameTimes,
      'errors': errors,
    }),
  );
  stdout.writeln(
    'Corrections native verification complete: ${errors.length} errors',
  );
}

Future<void> followup(Directory output, FortressRepository repository) async {
  final l10n = lookupAppLocalizations(const Locale('ar'));
  final chapter = repository.loadChapters().firstWhere(
    (c) => repository.loadDuas(c.chapterId).any((d) => d.contentId == 15),
  );
  final index = repository
      .loadDuas(chapter.chapterId)
      .indexWhere((d) => d.contentId == 15);
  Future<void> scene({
    bool browse = true,
    String locale = 'ar',
    ThemeMode mode = ThemeMode.dark,
    Size size = const Size(1200, 850),
  }) async {
    previewExpanded.value = true;
    config.value = (
      chapterId: chapter.chapterId,
      index: index,
      browse: browse,
      locale: locale,
      mode: mode,
      size: size,
      scale: 1,
      palette: AppPalette.manuscript,
    );
    await Future<void>.delayed(const Duration(seconds: 1));
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> pointer(Offset point) async {
    GestureBinding.instance.handlePointerEvent(
      PointerDownEvent(
        pointer: 220,
        position: point,
        buttons: kPrimaryButton,
        kind: ui.PointerDeviceKind.mouse,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    GestureBinding.instance.handlePointerEvent(
      PointerUpEvent(
        pointer: 220,
        position: point,
        kind: ui.PointerDeviceKind.mouse,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  await scene();
  await snap(output, 'expanded-card');
  await tapProductionWidget<FortressDhikrText>();
  await Future<void>.delayed(const Duration(milliseconds: 400));
  if (previewExpanded.value)
    throw StateError('Actual body pointer did not collapse card');
  await snap(output, 'collapsed-preview');
  await tapProductionWidget<FTile>();
  await Future<void>.delayed(const Duration(milliseconds: 400));
  await press(l10n.fortressBenefit);
  await snap(output, 'browse-benefit-backdrop');
  await tapText(l10n.fortressSharh);
  await snap(output, 'browse-sharh-after-tab');
  await tapText(l10n.fortressRelatedHadith);
  await snap(output, 'browse-hadith-after-tab');
  await pointer(const Offset(1050, 350));
  if (widgetWhere<FTabs>((_) => true) != null)
    throw StateError('Outside pointer did not dismiss sheet');
  await scene(locale: 'en', mode: ThemeMode.light, size: const Size(800, 900));
  await press(lookupAppLocalizations(const Locale('en')).fortressBenefit);
  await snap(output, 'compact-light-sheet');
  await scene(browse: false);
  await press(l10n.fortressSourceReference);
  await tapText(l10n.fortressBenefit);
  await snap(output, 'focus-benefit-after-tab');
  await scene();
  await press(l10n.fortressShare);
  await selectIncludes({...FortressShareInclude.values});
  final slider = widgetWhere<FSlider>((_) => true)!;
  (slider.control as dynamic).onChange(FSliderValue(max: .5));
  await Future<void>.delayed(const Duration(seconds: 1));
  await tapText('PDF');
  await snap(output, 'share-slider-actions');
  final plan = widgetWhere<FortressBookletPreview>((_) => true)!.plan;
  var progressCaptured = false;
  final captureJob = Completer<void>();
  final watch = Timer.periodic(const Duration(milliseconds: 30), (_) {
    final progress = widgetWhere<FDeterminateProgress>((_) => true)?.value ?? 0;
    if (progress >= .5 && !progressCaptured) {
      progressCaptured = true;
      snap(output, 'pdf-generating').then((_) => captureJob.complete());
    }
  });
  await press(l10n.fortressSavePdf);
  while (widgetWhere<FDeterminateProgress>((_) => true) != null) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  watch.cancel();
  if (progressCaptured) await captureJob.future;
  if (widgetWhere<FToast>((_) => true) == null)
    throw StateError('Export success toast was not reached');
  // Settle the toast entrance before assessing its bounds and content.
  await Future<void>.delayed(const Duration(milliseconds: 700));
  await snap(output, 'export-ready-toast');

  // Compare the previous main-isolate PDF assembly with the production worker,
  // using exactly the same rendered pages and 16 ms event-loop heartbeat.
  final measurement = await Directory('${output.path}/pdf-measurement')
      .create();
  final paths = <String>[];
  for (var i = 0; i < plan.pages.length; i++) {
    final file = File('${measurement.path}/$i.png');
    await file.writeAsBytes(await plan.png(i));
    paths.add(file.path);
  }
  Future<Map<String, int>> measure(Future<void> Function() task) async {
    final clock = Stopwatch()..start();
    var previous = 0;
    var largestGap = 0;
    var ticks = 0;
    final timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final now = clock.elapsedMicroseconds;
      final gap = now - previous;
      if (gap > largestGap) largestGap = gap;
      previous = now;
      ticks++;
    });
    await task();
    await Future<void>.delayed(const Duration(milliseconds: 32));
    timer.cancel();
    return {
      'elapsed_us': clock.elapsedMicroseconds,
      'max_heartbeat_gap_us': largestGap,
      'ticks': ticks,
    };
  }

  final before = await measure(() async {
    final document = pdf.Document();
    for (final path in paths) {
      final image = pdf.MemoryImage(await File(path).readAsBytes());
      document.addPage(
        pdf.Page(
          pageFormat: const PdfPageFormat(432, 540),
          margin: pdf.EdgeInsets.zero,
          build: (_) => pdf.Image(image, fit: pdf.BoxFit.fill),
        ),
      );
    }
    await File('${measurement.path}/before.pdf')
        .writeAsBytes(await document.save(), flush: true);
  });
  final after = await measure(
    () => FortressPdfExport().run(
      pages: paths,
      destination: '${measurement.path}/after.pdf',
      onProgress: (_) {},
    ),
  );
  await File('${output.path}/followup-report.json').writeAsString(
    jsonEncode({
      'source': 'Production native widgets and bundled chapter; actual body and outside pointer interactions',
      'chapter': chapter.chapterId,
      'pages': plan.pages.length,
      'before_main_pdf': before,
      'after_worker_pdf': after,
      'errors': errors,
    }),
  );
  stdout.writeln(
    'Followup native complete: ${errors.length} errors; PDF heartbeat before=$before after=$after',
  );
}

Future<void> rtlReview(
  Directory output,
  FortressRepository repository,
  ProviderContainer container,
  int chapterId,
  int short,
) async {
  final ar = lookupAppLocalizations(const Locale('ar'));
  final chapter = repository.loadChapters().firstWhere(
    (c) => c.chapterId == chapterId,
  );
  final dua = repository.loadDuas(chapterId)[short];
  Future<void> scene({
    required bool browse,
    String locale = 'ar',
    ThemeMode mode = ThemeMode.dark,
    Size size = const Size(1600, 950),
  }) async {
    config.value = (
      chapterId: chapterId,
      index: short,
      browse: browse,
      locale: locale,
      mode: mode,
      size: size,
      scale: 1,
      palette: AppPalette.manuscript,
    );
    await Future<void>.delayed(const Duration(seconds: 1));
    if (browse) {
      container
          .read(fortressScreenControllerProvider.notifier)
          .selectSearchTitle(chapter);
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }
    await WidgetsBinding.instance.endOfFrame;
  }

  await scene(browse: true);
  await snap(output, 'full-browse-before-sheet');
  BuildContext? detailContext;
  visit(capture.currentContext! as Element, (e) {
    if (e.widget is FortressCategoryDetailView) detailContext = e;
  });
  if (detailContext == null)
    throw StateError('Production full browse was not mounted');
  showFortressStudySheet(detailContext!, dua, kind: FortressDetailKind.hadith);
  await Future<void>.delayed(const Duration(seconds: 1));
  await snap(output, 'full-browse-sheet-catalog-backdrop');
  await tapText(ar.fortressBenefit);
  await snap(output, 'full-browse-sheet-five-tabs');
  await tapProductionWidget<FModalBarrier>();
  await Future<void>.delayed(const Duration(milliseconds: 500));
  if (widgetWhere<FTabs>(
        (w) => w.children.any(
          (e) =>
              e.label is Text && (e.label as Text).data == ar.fortressBenefit,
        ),
      ) !=
      null)
    throw StateError('Full browse barrier failed to dismiss');
  reviewFullBrowse = false;
  await scene(browse: true, size: const Size(1200, 850));
  await snap(output, 'rtl-expanded-actions');
  reviewFullBrowse = true;
  await scene(browse: false);
  await press(ar.fortressSourceReference);
  await tapText(ar.fortressBenefit);
  await snap(output, 'focus-light-backdrop-five-tabs');
  final counter = widgetWhere<FTappable>(
    (w) => w.key == const ValueKey('fortress-counter'),
  )!;
  counter.onPress!();
  await Future<void>.delayed(const Duration(milliseconds: 400));
  await snap(output, 'focus-counting-with-details');
  await scene(
    browse: false,
    locale: 'en',
    mode: ThemeMode.light,
    size: const Size(800, 900),
  );
  await press(
    lookupAppLocalizations(const Locale('en')).fortressSourceReference,
  );
  await snap(output, 'compact-english-light-five-tabs');
  config.value = (
    chapterId: chapterId,
    index: short,
    browse: false,
    locale: 'en',
    mode: ThemeMode.light,
    size: const Size(800, 900),
    scale: 1.3,
    palette: AppPalette.manuscript,
  );
  await Future<void>.delayed(const Duration(seconds: 1));
  await press(
    lookupAppLocalizations(const Locale('en')).fortressSourceReference,
  );
  await snap(output, 'compact-english-enlarged-five-tabs');
  // Reuse the earlier interaction matrix for compact RTL actions, actual exports,
  // slider endpoints and worker heartbeat. Its browse scenes use the full screen
  // in this run; use a direct focus share instead below.
  await scene(browse: false);
  await press(ar.fortressShare);
  await selectIncludes({...FortressShareInclude.values});
  await tapText('PDF');
  await snap(output, 'rtl-export-actions');
  var captured = false;
  Future<void>? pending;
  final watch = Timer.periodic(const Duration(milliseconds: 30), (_) {
    if (widgetWhere<FDeterminateProgress>((_) => true) != null && !captured) {
      captured = true;
      pending = snap(output, 'rtl-export-cancel');
    }
  });
  await press(ar.fortressSavePdf);
  while (widgetWhere<FDeterminateProgress>((_) => true) != null) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  watch.cancel();
  await pending;
  await Future<void>.delayed(const Duration(milliseconds: 700));
  await snap(output, 'rtl-export-ready');
  final exports = Directory('${output.path}/Tawaq')
      .listSync()
      .whereType<Directory>()
      .toList();
  if (exports.isEmpty ||
      exports.any((d) => d.path.contains('.tawaq-fortress-')))
    throw StateError('Grouped exports were not finalized cleanly');
  await File('${output.path}/rtl-report.json').writeAsString(
    jsonEncode({
      'scope': 'Native Linux production full MuslimFortressScreen and focus/share surfaces, isolated settings and export paths',
      'chapter': chapterId,
      'content': dua.contentId,
      'exports': exports.map((d) => d.path).toList(),
      'errors': errors,
    }),
  );
  stdout.writeln(
    'RTL native complete: ${errors.length} errors; exports under Tawaq',
  );
}
