import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_reference_logic.dart';
import 'package:tawaq/feature/quran/presentation/hooks/quran_ayah_selection.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_search.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/theme/theme.dart';

/// Typing pause before a bounded local search; feedback renders immediately.
const kQuranSearchDebounce = Duration(milliseconds: 120);

/// One search field with explicit, grouped navigation destinations.
class QuranSearchField extends HookConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.watch(quranMushafControllerProvider);
    final search = useMemoized(() => QuranSearch(controller), [controller]);
    final text = useTextEditingController();
    final focus = useFocusNode();
    final query = useState('');
    final results = useState<AsyncValue<List<QuranSearchResult>>>(
      const AsyncData([]),
    );
    final active = useState(0);
    final navigating = useState(false);
    final popover = useRef<FPopoverController?>(null);
    final retry = useState(0);
    final scroll = useScrollController();
    final resultKeys = useRef(<GlobalKey>[]);
    useEffect(() {
      void changed() {
        query.value = text.text;
        if (focus.hasFocus && text.text.isNotEmpty && !navigating.value) {
          unawaited(popover.value?.show());
        }
      }

      text.addListener(changed);
      return () => text.removeListener(changed);
    }, [text]);
    useEffect(() {
      var cancelled = false;
      active.value = 0;
      if (query.value.trim().isEmpty) {
        results.value = const AsyncData([]);
        return null;
      }
      results.value = const AsyncLoading();
      final timer = Timer(kQuranSearchDebounce, () async {
        try {
          final found = await search.search(query.value);
          if (cancelled) return;
          resultKeys.value = List.generate(found.length, (_) => GlobalKey());
          results.value = AsyncData(found);
        } catch (error, stack) {
          if (!cancelled) results.value = AsyncError(error, stack);
        }
      });
      return () {
        cancelled = true;
        timer.cancel();
      };
    }, [search, query.value, retry.value]);

    void open() {
      focus.requestFocus();
      unawaited(popover.value?.show());
    }

    useRegisterAppSearchFocus(open);

    Future<void> choose(QuranSearchResult result) async {
      if (navigating.value) return;
      navigating.value = true;
      try {
        switch (result.kind) {
          case QuranSearchKind.surah:
            await controller.jumpToSurah(result.number);
          case QuranSearchKind.juz:
            await controller.jumpToJuz(result.number);
          case QuranSearchKind.hizb:
            await controller.jumpToHizb(result.number);
          case QuranSearchKind.ayah:
            await jumpToQuranAyah(ref, result.ayah!);
        }
        if (!context.mounted) return;
        await popover.value?.hide();
        text.clear();
        focus.unfocus();
      } catch (error, stack) {
        if (context.mounted) results.value = AsyncError(error, stack);
      } finally {
        if (context.mounted) navigating.value = false;
      }
    }

    String category(QuranSearchKind kind) => switch (kind) {
      QuranSearchKind.surah => l10n.quranSearchSurahs,
      QuranSearchKind.juz => l10n.quranSearchJuzs,
      QuranSearchKind.hizb => l10n.quranSearchHizbs,
      QuranSearchKind.ayah => l10n.quranSearchAyahs,
    };
    String title(QuranSearchResult result) {
      if (result.kind == QuranSearchKind.juz) {
        return l10n.juzLabel(result.number);
      }
      if (result.kind == QuranSearchKind.hizb) {
        return l10n.hizbLabel(result.number);
      }
      final name = AyahReferenceLogic.surahName(
        result.surah,
        result.surah?.number ?? result.ayah!.surahNumber,
        preferArabic: Localizations.localeOf(context).languageCode == 'ar',
        fallbackName: '',
      );
      return result.kind == QuranSearchKind.ayah
          ? l10n.surahAyahInfo(name, result.number)
          : '${result.number}. $name';
    }

    void submit() {
      final found = results.value.value;
      if (found != null && found.isNotEmpty) {
        unawaited(choose(found[active.value.clamp(0, found.length - 1)]));
      }
    }

    return FPopover(
      autofocus: false,
      childFocusNode: focus,
      semanticsLabel: l10n.searchQuran,
      popoverAnchor: AlignmentDirectional.topStart,
      childAnchor: AlignmentDirectional.bottomStart,
      constraints: selectPopoverPortalConstraints(
        context,
        maxHeight: 420,
        maxHeightFraction: .65,
      ),
      popoverBuilder: (context, popup) => ListenableBuilder(
        listenable: Listenable.merge([query, results, active, navigating]),
        builder: (context, _) {
          final found = results.value.value ?? const <QuranSearchResult>[];
          Widget message(String value) => Padding(
            key: const ValueKey('quran-search-message'),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(value, style: context.theme.typography.body.sm),
          );
          if (query.value.trim().isEmpty) {
            return message(l10n.quranUnifiedSearchHelp);
          }
          if (results.value.isLoading || navigating.value) {
            return Padding(
              key: const ValueKey('quran-search-loading'),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                spacing: AppSpacing.sm,
                children: [
                  const FCircularProgress.loader(),
                  Text(l10n.loading),
                ],
              ),
            );
          }
          if (results.value.hasError) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.sm,
                children: [
                  Text(l10n.quranSearchFailed),
                  FButton(
                    onPress: () => retry.value++,
                    child: Text(l10n.retryAction),
                  ),
                ],
              ),
            );
          }
          if (found.isEmpty) return message(l10n.noResultsFound);
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: RawScrollbar(
              thumbColor: context.theme.colors.mutedForeground.withValues(
                alpha: .5,
              ),
              thickness: 4,
              radius: const Radius.circular(4),
              controller: scroll,
              thumbVisibility: true,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context)
                    .copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  key: const ValueKey('quran-search-results'),
                  controller: scroll,
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var index = 0; index < found.length; index++) ...[
                        if (index == 0 ||
                            found[index - 1].kind != found[index].kind)
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              AppSpacing.md,
                              AppSpacing.md,
                              AppSpacing.md,
                              AppSpacing.xs,
                            ),
                            child: Text(
                              category(found[index].kind),
                              style: context.theme.typography.body.xs.copyWith(
                                color: context.theme.colors.mutedForeground,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        MouseRegion(
                          onHover: (_) => active.value = index,
                          child: FItem.raw(
                            onFocusChange: (focused) {
                              if (focused) active.value = index;
                            },
                            onHoverChange: (hovered) {
                              if (hovered) active.value = index;
                            },
                            style: .delta(
                              backgroundColor: .delta([
                                .all(Colors.transparent),
                              ]),
                              contentDecoration: .delta([
                                .all(
                                  .shapeDelta(
                                    color: active.value == index
                                        ? context.theme.colors.secondary
                                        : Colors.transparent,
                                  ),
                                ),
                              ]),
                            ),
                            key: resultKeys.value[index],
                            selected: active.value == index,
                            enabled: !navigating.value,
                            onPress: () => choose(found[index]),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: AppSpacing.xs,
                              children: [
                                Text(
                                  title(found[index]),
                                  style: context.theme.typography.body.sm
                                      .copyWith(fontWeight: FontWeight.w500),
                                  textHeightBehavior:
                                      const TextHeightBehavior(),
                                ),
                                if (found[index].kind ==
                                        QuranSearchKind.surah &&
                                    (found[index].surah?.ayahCount != null ||
                                        found[index].surah?.startPage != null))
                                  Text(
                                    [
                                      if (found[index].surah?.ayahCount != null)
                                        l10n.shareVerseCount(
                                          found[index].surah!.ayahCount!,
                                        ),
                                      if (found[index].surah?.startPage != null)
                                        l10n.pageLabel(
                                          found[index].surah!.startPage!,
                                        ),
                                    ].join(' • '),
                                    style: context.theme.typography.body.xs
                                        .copyWith(
                                          color: context
                                              .theme
                                              .colors
                                              .mutedForeground,
                                        ),
                                    textHeightBehavior:
                                        const TextHeightBehavior(),
                                  ),
                                if (found[index].ayah != null &&
                                    found[index].kind != QuranSearchKind.ayah)
                                  Text(
                                    l10n.surahAyahInfo(
                                      AyahReferenceLogic.surahName(
                                        found[index].surah,
                                        found[index].ayah!.surahNumber,
                                        preferArabic:
                                            Localizations.localeOf(context)
                                                .languageCode ==
                                            'ar',
                                        fallbackName: '',
                                      ),
                                      found[index].ayah!.numberInSurah,
                                    ),
                                    style: context.theme.typography.body.xs
                                        .copyWith(
                                          color: context
                                              .theme
                                              .colors
                                              .mutedForeground,
                                        ),
                                    textHeightBehavior:
                                        const TextHeightBehavior(),
                                  ),
                                if (found[index].ayah != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.xs,
                                    ),
                                    child: Text(
                                      found[index].ayah!.uthmaniText ??
                                          found[index].ayah!.textPlain ??
                                          '',
                                      textDirection: TextDirection.rtl,
                                      textHeightBehavior:
                                          const TextHeightBehavior(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: FontFamily.uthmanicHafs,
                                        color: context
                                            .theme
                                            .colors
                                            .mutedForeground,
                                        fontSize: 20,
                                        height: 1.8,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      builder: (context, popup, _) {
        popover.value = popup;
        return Focus(
          onKeyEvent: (_, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              unawaited(popup.hide());
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                event.logicalKey == LogicalKeyboardKey.arrowUp) {
              unawaited(popup.show());
              final count = results.value.value?.length ?? 0;
              if (count > 0) {
                active.value =
                    (active.value +
                            (event.logicalKey == LogicalKeyboardKey.arrowDown
                                ? 1
                                : -1))
                        .clamp(0, count - 1);
                final itemContext =
                    resultKeys.value[active.value].currentContext;
                if (itemContext != null) {
                  Scrollable.ensureVisible(itemContext, alignment: .5);
                }
              }
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: FTextField(
            control: FTextFieldControl.managed(controller: text),
            focusNode: focus,
            hint: l10n.quranUnifiedSearchHint,
            onTap: open,
            onTapAlwaysCalled: true,
            onSubmit: (_) => submit(),
            textInputAction: TextInputAction.search,
            suffixBuilder: query.value.isEmpty
                ? null
                : (_, _, _) => FButton.icon(
                    variant: .ghost,
                    semanticsLabel: l10n.clearSearchAction,
                    onPress: () {
                      text.clear();
                      open();
                    },
                    child: const Icon(FLucideIcons.x, size: 14),
                  ),
            prefixBuilder: (_, _, _) => const Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Icon(FLucideIcons.search, size: 16),
            ),
          ),
        );
      },
    );
  }
}
