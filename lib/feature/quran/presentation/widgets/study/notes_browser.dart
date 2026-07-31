import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/text/arabic_search_normalize.dart';
import 'package:tawaq/core/widgets/animation_entry.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/core/widgets/dialog_shell.dart';
import 'package:tawaq/feature/quran/domain/models/quran_ui_models.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_reference_logic.dart';
import 'package:tawaq/feature/quran/presentation/hooks/quran_ayah_selection.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_notes_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/surah_name_text.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// Max note cards that play staggered entrance animation.
const kNotesBrowserStaggerCap = 8;

/// Filters [entries] by [query] against note text, ayah preview, and surah
/// name.
List<QuranNoteEntry> filterQuranNotes(
  List<QuranNoteEntry> entries,
  String query,
  String Function(int surahNumber) surahNameOf,
) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return entries;
  return [
    for (final entry in entries)
      if (arabicSearchContains(entry.note.text, trimmed) ||
          arabicSearchContains(entry.ayahPreview, trimmed) ||
          arabicSearchContains(surahNameOf(entry.surahNumber), trimmed))
        entry,
  ];
}

/// Relative-time label for a note; wording lives entirely in ARB plurals.
String noteTimeLabel(
  AppLocalizations l10n,
  DateTime when, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final whenLocal = when.toLocal();
  final currentLocal = current.toLocal();

  final whenDay = DateTime(whenLocal.year, whenLocal.month, whenLocal.day);
  final today = DateTime(
    currentLocal.year,
    currentLocal.month,
    currentLocal.day,
  );
  final yesterday = today.subtract(const Duration(days: 1));

  if (whenDay == today) return l10n.noteTimeToday;
  if (whenDay == yesterday) return l10n.noteTimeYesterday;

  final days = today.difference(whenDay).inDays;
  if (days < 7) return l10n.noteTimeDaysAgo(days);

  final weeks = days ~/ 7;
  if (weeks < 5) return l10n.noteTimeWeeksAgo(weeks);

  final months = days ~/ 30;
  if (months < 12) return l10n.noteTimeMonthsAgo(months.clamp(1, 11));

  final years = days ~/ 365;
  return l10n.noteTimeYearsAgo(years.clamp(1, 999));
}

sealed class _NotesListItem {
  const _NotesListItem();
}

class _SurahHeaderItem extends _NotesListItem {
  const _SurahHeaderItem(this.surahNumber);
  final int surahNumber;
}

class _NoteCardItem extends _NotesListItem {
  const _NoteCardItem(this.entry, this.staggerIndex);
  final QuranNoteEntry entry;
  final int staggerIndex;
}

List<_NotesListItem> _buildGroupedItems(List<QuranNoteEntry> entries) {
  final items = <_NotesListItem>[];
  var lastSurah = -1;
  var stagger = 0;
  for (final entry in entries) {
    if (entry.surahNumber != lastSurah) {
      lastSurah = entry.surahNumber;
      items.add(_SurahHeaderItem(entry.surahNumber));
    }
    items.add(_NoteCardItem(entry, stagger));
    stagger++;
  }
  return items;
}

/// Searchable, surah-grouped browser of all saved Quran reflections.
class NotesBrowser extends HookConsumerWidget {
  /// Creates a [NotesBrowser].
  const NotesBrowser({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final controller = ref.watch(quranMushafControllerProvider);
    final notesAsync = ref.watch(quranAllNotesProvider);

    final query = useState('');
    final debouncedQuery = useState('');
    final searchController = useTextEditingController();

    final commitQuery = useCallback(
      () => debouncedQuery.value = query.value,
      const [],
    );
    final debouncedCommit = useDebouncedCallback(commitQuery);

    String surahNameOf(int surahNumber) {
      final surah = controller.getSurahSync(surahNumber);
      return AyahReferenceLogic.surahName(
        surah,
        surahNumber,
        preferArabic: isArabic,
        fallbackName: l10n.surahNameDefault(surahNumber),
      );
    }

    return notesAsync.when(
      loading: () => const Center(child: FCircularProgress()),
      error: (error, _) => Center(
        child: Text(
          error.toString(),
          style: typography.body.sm.copyWith(color: colors.destructive),
          textAlign: TextAlign.center,
        ),
      ),
      data: (allEntries) {
        final filtered = filterQuranNotes(
          allEntries,
          debouncedQuery.value,
          surahNameOf,
        );
        final surahCount = filtered.map((e) => e.surahNumber).toSet().length;
        final grouped = _buildGroupedItems(filtered);

        final Widget body;
        if (allEntries.isEmpty) {
          body = KeyedSubtree(
            key: const ValueKey('empty'),
            child: _NotesEmptyState(
              icon: FLucideIcons.penLine,
              message: l10n.noReflectionsYet,
            ),
          );
        } else if (filtered.isEmpty) {
          body = KeyedSubtree(
            key: const ValueKey('no-match'),
            child: _NotesEmptyState(
              icon: FLucideIcons.searchX,
              message: l10n.noReflectionsMatchSearch,
            ),
          );
        } else {
          body = KeyedSubtree(
            key: const ValueKey('list'),
            child: ListView.builder(
              padding: hoverCardListPadding(bottom: AppSpacing.lg),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final item = grouped[index];
                return switch (item) {
                  _SurahHeaderItem(:final surahNumber) => Padding(
                    padding: EdgeInsets.only(
                      top: index == 0 ? 0 : AppSpacing.md,
                      bottom: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        SurahNameText(
                          surahNameOf(surahNumber),
                          style: typography.body.md.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Divider(
                            height: 1,
                            color: colors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Gap >= the glow's downward reach so the next card does not
                  // paint over a hovered card's glow.
                  _NoteCardItem(:final entry, :final staggerIndex) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: staggerIndex < kNotesBrowserStaggerCap
                        ? AnimationEntry(
                            key: ValueKey(entry.ayahId),
                            animateOnce: true,
                            delay: Duration(milliseconds: staggerIndex * 40),
                            child: _NoteCard(
                              entry: entry,
                              surahName: surahNameOf(entry.surahNumber),
                            ),
                          )
                        : _NoteCard(
                            key: ValueKey(entry.ayahId),
                            entry: entry,
                            surahName: surahNameOf(entry.surahNumber),
                          ),
                  ),
                };
              },
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Matches the list's glow gutter so the field lines up with cards.
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kHoverCardGlowGutter,
              ),
              // The panel card is `secondary`; a recessed fill keeps the field
              // from melting into it.
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: theme.radii.md,
                ),
                child: FTextField(
                  control: FTextFieldControl.managed(
                    controller: searchController,
                    onChange: (value) {
                      query.value = value.text;
                      debouncedCommit();
                    },
                  ),
                  hint: l10n.searchYourReflections,
                  prefixBuilder: (context, style, states) => Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: AppSpacing.sm,
                    ),
                    child: Icon(
                      FLucideIcons.search,
                      size: 16,
                      color: colors.mutedForeground,
                    ),
                  ),
                  style: const .delta(
                    contentPadding: .value(EdgeInsets.all(AppSpacing.md)),
                  ),
                ),
              ),
            ),
            if (allEntries.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kHoverCardGlowGutter,
                ),
                child: Text(
                  l10n.reflectionsSummary(filtered.length, surahCount),
                  style: typography.body.sm.copyWith(
                    color: Color.lerp(
                      colors.mutedForeground,
                      colors.foreground,
                      0.25,
                    ),
                  ),
                ),
              ),
            ],
            Expanded(
              child: AnimatedSwitcher(
                duration: theme.durations.fast,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                // Default layout builder stacks with Clip.hardEdge, which is a
                // second clip on top of the viewport's for card glows.
                layoutBuilder: (currentChild, previousChildren) => Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [...previousChildren, ?currentChild],
                ),
                child: body,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NotesEmptyState extends StatelessWidget {
  const _NotesEmptyState({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: colors.mutedForeground),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: typography.body.sm.copyWith(
                color: Color.lerp(
                  colors.mutedForeground,
                  colors.foreground,
                  0.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends HookConsumerWidget {
  const _NoteCard({
    required this.entry,
    required this.surahName,
    super.key,
  });

  final QuranNoteEntry entry;
  final String surahName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;
    final l10n = context.l10n;
    final (:isHovered, :setHovered) = useHoverState();

    Future<void> openAyah() async {
      final mushaf = ref.read(quranMushafControllerProvider);
      final ayah = await mushaf.getAyah(entry.ayahId);
      if (!context.mounted) return;
      await jumpToQuranAyah(ref, ayah);
      ref
          .read(quranScreenSettingsProvider.notifier)
          .setActiveStudyTab(StudyPanelTab.currentAyah);
    }

    Future<void> confirmDelete() async {
      final confirmed = await showFDialog<bool>(
        context: context,
        builder: (dialogContext, style, animation) {
          final constraints = dialogConstraints(
            dialogContext,
            preferredWidth: 400,
            preferredHeight: 220,
            minWidth: 280,
          );
          return FDialog(
            style: style,
            animation: animation,
            constraints: constraints,
            builder: (context, dialogStyle) => ForuiDialogLayout(
              style: dialogStyle,
              title: Text(l10n.deleteReflection),
              body: Text(l10n.deleteReflectionConfirm),
              actions: [
                FButton(
                  variant: .secondary,
                  onPress: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.cancel),
                ),
                FButton(
                  variant: .destructive,
                  onPress: () => Navigator.of(dialogContext).pop(true),
                  child: Text(l10n.deleteReflection),
                ),
              ],
            ),
          );
        },
      );
      if (confirmed != true || !context.mounted) return;
      await ref.read(quranNotesProvider(entry.ayahId).notifier).deleteNote();
    }

    final ayahBadge = '${l10n.ayahLabel} ${entry.numberInSurah}';
    final timeLabel = noteTimeLabel(l10n, entry.note.updatedAt);
    final semanticsLabel =
        '$surahName, $ayahBadge, $timeLabel, ${entry.note.text}';

    return HoverCard(
      onPress: () => unawaited(openAyah()),
      semanticsLabel: semanticsLabel,
      padding: const EdgeInsets.all(AppSpacing.md),
      // The panel card already uses `secondary`; recess the note cards so the
      // list reads as distinct rows instead of one flat block.
      backgroundColor: colors.background,
      borderColor: colors.border,
      child: MouseRegion(
        onEnter: (_) => setHovered(value: true),
        onExit: (_) => setHovered(value: false),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                FBadge(
                  variant: .secondary,
                  child: Text(ayahBadge),
                ),
                const Spacer(),
                Text(
                  timeLabel,
                  style: typography.body.xs.copyWith(
                    color: Color.lerp(
                      colors.mutedForeground,
                      colors.foreground,
                      0.2,
                    ),
                  ),
                ),
                AnimatedOpacity(
                  opacity: isHovered ? 1 : 0,
                  duration: theme.durations.fast,
                  child: IgnorePointer(
                    ignoring: !isHovered,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: AppSpacing.sm,
                      ),
                      child: FTooltip(
                        tipBuilder: (_, _) => Text(l10n.deleteReflection),
                        child: FButton.icon(
                          variant: .ghost,
                          onPress: () => unawaited(confirmDelete()),
                          child: Icon(
                            FLucideIcons.trash2,
                            size: 16,
                            color: colors.destructive,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (entry.ayahPreview.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                entry.ayahPreview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.rtl,
                // Uthmani glyphs render small at body sizes and need extra
                // line height to keep marks from clipping.
                style: typography.body.sm.copyWith(
                  fontFamily: FontFamily.uthmanicHafs,
                  fontSize: 15,
                  height: 1.9,
                  color: Color.lerp(
                    colors.foreground,
                    colors.mutedForeground,
                    0.3,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              entry.note.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: typography.body.sm.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.5,
                color: colors.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
