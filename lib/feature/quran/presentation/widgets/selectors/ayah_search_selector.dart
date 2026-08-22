import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/empty_state_panel.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_reference_logic.dart';
import 'package:tawaq/feature/quran/presentation/hooks/quran_ayah_selection.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/ayah_search_result_item.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// Ayah search field for searching through the Quran.
class AyahSearchSelector extends HookConsumerWidget {
  /// Creates an [AyahSearchSelector] instance.
  const AyahSearchSelector({
    this.focusNode,
    this.showLabel = true,
    super.key,
  });

  /// Optional focus node for keyboard shortcut focus (Ctrl+K).
  final FocusNode? focusNode;

  /// Whether the field label is shown above the field.
  final bool showLabel;

  String _surahName(
    MushafReaderController controller,
    int surahNumber,
    AppLocalizations l10n,
    bool preferArabic,
  ) {
    return AyahReferenceLogic.surahName(
      controller.getSurahSync(surahNumber),
      surahNumber,
      preferArabic: preferArabic,
      fallbackName: '',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(quranMushafControllerProvider);
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final autocompleteController = useMemoized(FAutocompleteController.new);
    useEffect(() => autocompleteController.dispose, [autocompleteController]);
    final localFocusNode = useFocusNode();
    final effectiveFocusNode = focusNode ?? localFocusNode;
    final warmedSearchIndex = useRef(false);

    useEffect(() {
      void onFocusChange() {
        if (!effectiveFocusNode.hasFocus || warmedSearchIndex.value) return;
        warmedSearchIndex.value = true;
        unawaited(controller.warmUpSearchIndex());
      }

      effectiveFocusNode.addListener(onFocusChange);
      return () => effectiveFocusNode.removeListener(onFocusChange);
    }, [effectiveFocusNode, controller]);

    return QuranSemantics.labeledControl(
      name: l10n.searchQuran,
      excludeChild: true,
      child: FAutocomplete<Ayah>.builder(
        focusNode: effectiveFocusNode,
        hint: l10n.searchQuran,
        label: showLabel ? Text(l10n.searchQuran) : const SizedBox.shrink(),
        textDirection: isArabic ? TextDirection.rtl : null,
        textInputAction: TextInputAction.search,
        prefixBuilder: (context, style, states) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: QuranSemantics.decorative(
            Icon(
              FLucideIcons.search,
              color: colors.mutedForeground,
              size: 14,
            ),
          ),
        ),
        contentConstraints: selectPopoverPortalConstraints(
          context,
          maxHeight: 400,
        ),
        style: autocompleteStyle(
          colors: colors,
          style: theme.style,
          typography: typography,
        ),
        filter: (query) => filterAyahsForSearch(controller, query),
        format: (ayah) => l10n.surahAyahInfo(
          _surahName(controller, ayah.surahNumber, l10n, isArabic),
          ayah.numberInSurah,
        ),
        parse: (_) => null,
        control: FAutocompleteControl.managed(
          controller: autocompleteController,
        ),
        contentEmptyBuilder: (context, style) => EmptyStatePanel(
          icon: FLucideIcons.searchX,
          title: l10n.noResultsFound,
          hint: l10n.tryDifferentSearchTerm,
          iconSize: 32,
          padding: const EdgeInsets.all(AppSpacing.lg),
        ),
        contentLoadingBuilder: (context, style) => const Padding(
          padding: EdgeInsets.all(24),
          child: FCircularProgress.loader(),
        ),
        onItemPress: (ayah) async {
          await jumpToQuranAyah(ref, ayah);
          autocompleteController.text = '';
        },
        contentBuilder: (context, query, ayahs) => ayahs
            .map(
              (ayah) => buildAyahSearchResultItem(
                context: context,
                ayah: ayah,
                controller: controller,
                isArabic: isArabic,
                l10n: l10n,
              ),
            )
            .toList(),
      ),
    );
  }
}
