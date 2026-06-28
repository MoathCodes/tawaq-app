import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/layout/centered_viewport_shell.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/scroll_overflow_hint_viewport.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_pick_intent.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/domain/services/reciter_tags.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/reciter_dialog_shared.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// Filters reciters that have at least one selectable moshaf for [intent].
List<Reciter> visibleReciters({
  required List<Reciter> filtered,
  required RecitationPickIntent intent,
}) {
  final visible = <Reciter>[];
  for (final reciter in filtered) {
    if (selectableMoshafs(reciter, intent).isEmpty) continue;
    visible.add(reciter);
  }
  return visible;
}

/// Returns moshafs the user can pick for the given [intent].
List<Moshaf> selectableMoshafs(Reciter reciter, RecitationPickIntent intent) {
  if (intent == RecitationPickIntent.ayahLevel) {
    return reciter.moshaf.where((m) => m.hasTiming).toList();
  }
  return reciter.moshaf;
}

sealed class ReciterListEntry {
  const ReciterListEntry();
}

final class ReciterRowEntry extends ReciterListEntry {
  const ReciterRowEntry(this.reciter);

  final Reciter reciter;
}

final class InlineMoshafEntry extends ReciterListEntry {
  const InlineMoshafEntry(this.reciter, this.moshaf);

  final Reciter reciter;
  final Moshaf moshaf;
}

List<ReciterListEntry> reciterListEntries({
  required List<Reciter> reciters,
  required RecitationPickIntent intent,
  Reciter? inlineRiwayahFor,
}) {
  final entries = <ReciterListEntry>[];
  for (final reciter in reciters) {
    entries.add(ReciterRowEntry(reciter));
    if (inlineRiwayahFor?.id == reciter.id) {
      final selectable = selectableMoshafs(reciter, intent);
      if (selectable.length > 1) {
        for (final moshaf in selectable) {
          entries.add(InlineMoshafEntry(reciter, moshaf));
        }
      }
    }
  }
  return entries;
}

/// Scrollable reciter list for the picker dialog.
class ReciterDialogListPane extends StatelessWidget {
  /// Creates the list pane.
  const ReciterDialogListPane({
    required this.reciters,
    required this.intent,
    required this.selectedReciterId,
    required this.selectedMoshafId,
    required this.focusedReciterId,
    required this.downloadedKeys,
    required this.onReciterPress,
    this.inlineRiwayahFor,
    this.onPick,
    this.applyingReciterId,
    super.key,
  });

  final List<Reciter> reciters;
  final RecitationPickIntent intent;
  final int? selectedReciterId;
  final int? selectedMoshafId;
  final int? focusedReciterId;
  final Set<(int, int)> downloadedKeys;
  final ValueChanged<Reciter> onReciterPress;
  final Reciter? inlineRiwayahFor;
  final void Function(Reciter reciter, Moshaf moshaf)? onPick;
  final int? applyingReciterId;

  @override
  Widget build(BuildContext context) {
    final entries = reciterListEntries(
      reciters: reciters,
      intent: intent,
      inlineRiwayahFor: inlineRiwayahFor,
    );

    return FTileGroup.builder(
      divider: FItemDivider.full,
      tileBuilder: (context, index) {
        if (index >= entries.length) return null;

        return switch (entries[index]) {
          ReciterRowEntry(:final reciter) => buildReciterTile(
            context,
            reciter: reciter,
            intent: intent,
            selectedReciterId: selectedReciterId,
            selectedMoshafId: selectedMoshafId,
            focusedReciterId: focusedReciterId,
            downloadedKeys: downloadedKeys,
            onReciterPress: onReciterPress,
            applying: applyingReciterId == reciter.id,
          ),
          InlineMoshafEntry(:final reciter, :final moshaf) =>
            buildInlineMoshafTile(
              context,
              reciter: reciter,
              moshaf: moshaf,
              intent: intent,
              selectedReciterId: selectedReciterId,
              selectedMoshafId: selectedMoshafId,
              downloadedKeys: downloadedKeys,
              onPick: onPick!,
            ),
        };
      },
      count: entries.length,
    );
  }
}

FTile buildReciterTile(
  BuildContext context, {
  required Reciter reciter,
  required RecitationPickIntent intent,
  required int? selectedReciterId,
  required int? selectedMoshafId,
  required int? focusedReciterId,
  required Set<(int, int)> downloadedKeys,
  required ValueChanged<Reciter> onReciterPress,
  bool applying = false,
}) {
  final l10n = context.l10n;
  final colors = context.theme.colors;
  final selectable = selectableMoshafs(reciter, intent);
  final isApplied = selectedReciterId == reciter.id;
  final isFocused = focusedReciterId == reciter.id;
  final activeMoshaf = isApplied && selectedMoshafId != null
      ? reciter.moshaf.where((m) => m.id == selectedMoshafId).firstOrNull
      : null;
  final multi = selectable.length > 1;

  return FTile(
    style: reciterTileStyle,
    prefix: Icon(
      FLucideIcons.mic,
      size: 17,
      color: isApplied || isFocused ? colors.primary : colors.mutedForeground,
    ),
    title: Text(
      reciter.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Text(
      activeMoshaf != null
          ? moshafPrimaryLabel(activeMoshaf, l10n)
          : multi
          ? l10n.quranReciterRiwayahCount(selectable.length)
          : moshafPrimaryLabel(selectable.first, l10n),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    details: ReciterHeaderMeta(
      reciter: reciter,
      downloadedKeys: downloadedKeys,
    ),
    suffix: applying
        ? const SizedBox(
            width: 16,
            height: 16,
            child: FCircularProgress(size: FCircularProgressSizeVariant.sm),
          )
        : multi
        ? Icon(
            isFocused ? FLucideIcons.chevronDown : FLucideIcons.chevronLeft,
            size: 16,
            color: colors.mutedForeground,
          )
        : (isApplied
              ? Icon(FLucideIcons.check, size: 16, color: colors.primary)
              : null),
    selected: isApplied || isFocused,
    onPress: () => onReciterPress(reciter),
  );
}

FTile buildInlineMoshafTile(
  BuildContext context, {
  required Reciter reciter,
  required Moshaf moshaf,
  required RecitationPickIntent intent,
  required int? selectedReciterId,
  required int? selectedMoshafId,
  required Set<(int, int)> downloadedKeys,
  required void Function(Reciter reciter, Moshaf moshaf) onPick,
}) {
  final l10n = context.l10n;
  final colors = context.theme.colors;
  final ayahIntent = intent == RecitationPickIntent.ayahLevel;
  final selectable = !ayahIntent || moshaf.hasTiming;
  final isApplied =
      selectedReciterId == reciter.id && selectedMoshafId == moshaf.id;
  final tags = moshafTags(moshaf.name);
  final primary = moshafPrimaryLabel(moshaf, l10n);
  final subtitle = selectable
      ? moshafSubtitle(moshaf: moshaf, tags: tags, l10n: l10n)
      : l10n.quranReciterSurahOnly;

  return FTile(
    style: riwayahTileStyle,
    enabled: selectable,
    prefix: MoshafPrefix(style: tags.style),
    title: Text(primary, maxLines: 2, overflow: TextOverflow.ellipsis),
    subtitle: subtitle == null ? null : Text(subtitle),
    details: MoshafMetaRow(
      moshaf: moshaf,
      downloaded: downloadedKeys.contains((reciter.id, moshaf.id)),
    ),
    suffix: isApplied
        ? Icon(FLucideIcons.check, size: 16, color: colors.primary)
        : null,
    selected: isApplied,
    onPress: selectable ? () => onPick(reciter, moshaf) : null,
  );
}

/// Detail pane showing riwayah options for the focused reciter.
class ReciterDialogRiwayahPane extends StatelessWidget {
  /// Creates the riwayah detail pane.
  const ReciterDialogRiwayahPane({
    required this.reciter,
    required this.intent,
    required this.selectedReciterId,
    required this.selectedMoshafId,
    required this.downloadedKeys,
    required this.onPick,
    super.key,
  });

  final Reciter? reciter;
  final RecitationPickIntent intent;
  final int? selectedReciterId;
  final int? selectedMoshafId;
  final Set<(int, int)> downloadedKeys;
  final void Function(Reciter reciter, Moshaf moshaf) onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final colors = theme.colors;

    if (reciter == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            l10n.quranSelectReciter,
            textAlign: TextAlign.center,
            style: theme.typography.body.sm.copyWith(
              color: colors.mutedForeground,
            ),
          ),
        ),
      );
    }

    final selectable = selectableMoshafs(reciter!, intent);
    if (selectable.length <= 1) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            l10n.quranReciterRiwayahCount(selectable.length),
            textAlign: TextAlign.center,
            style: theme.typography.body.sm.copyWith(
              color: colors.mutedForeground,
            ),
          ),
        ),
      );
    }

    return ReciterDialogMoshafGroup(
      reciter: reciter!,
      intent: intent,
      tileStyle: reciterTileStyle,
      selectedReciterId: selectedReciterId,
      selectedMoshafId: selectedMoshafId,
      downloadedKeys: downloadedKeys,
      onPick: onPick,
      label: Text(
        reciter!.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.typography.body.sm.copyWith(
          fontWeight: FontWeight.w700,
          color: colors.foreground,
        ),
      ),
    );
  }
}

/// Radio tile group for picking a moshaf within a reciter.
class ReciterDialogMoshafGroup extends StatelessWidget {
  /// Creates a moshaf select group.
  const ReciterDialogMoshafGroup({
    required this.reciter,
    required this.intent,
    required this.tileStyle,
    required this.selectedReciterId,
    required this.selectedMoshafId,
    required this.downloadedKeys,
    required this.onPick,
    this.label,
    super.key,
  });

  final Reciter reciter;
  final RecitationPickIntent intent;
  final FItemStyleDelta tileStyle;
  final int? selectedReciterId;
  final int? selectedMoshafId;
  final Set<(int, int)> downloadedKeys;
  final void Function(Reciter reciter, Moshaf moshaf) onPick;
  final Widget? label;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.theme.colors;
    final ayahIntent = intent == RecitationPickIntent.ayahLevel;
    final selectable = selectableMoshafs(reciter, intent);
    final initial = selectedReciterId == reciter.id && selectedMoshafId != null
        ? ReciterMoshafKey(reciter.id, selectedMoshafId!)
        : null;

    return LayoutBuilder(
      builder: (context, constraints) => ScrollOverflowHintViewport(
        builder: (controller) => centeredViewportScrollTab(
          controller: controller,
          maxContentWidth: constraints.maxWidth,
          child: FSelectTileGroup<ReciterMoshafKey>(
            key: ValueKey('Tile-Group-Riwayat${reciter.id}'),
            divider: FItemDivider.full,
            label: label,
            control: FMultiValueControl.managedRadio(
              initial: initial,
              onChange: (selected) {
                final key = selected.firstOrNull;
                if (key == null) return;
                final moshaf = reciter.moshaf.firstWhere(
                  (m) => m.id == key.moshafId,
                );
                onPick(reciter, moshaf);
              },
            ),
            children: [
              for (final moshaf in selectable)
                _buildMoshafTile(
                  reciter: reciter,
                  moshaf: moshaf,
                  ayahIntent: ayahIntent,
                  downloadedKeys: downloadedKeys,
                  l10n: l10n,
                  colors: colors,
                  tileStyle: tileStyle,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static FSelectTile<ReciterMoshafKey> _buildMoshafTile({
    required Reciter reciter,
    required Moshaf moshaf,
    required bool ayahIntent,
    required Set<(int, int)> downloadedKeys,
    required AppLocalizations l10n,
    required FColors colors,
    required FItemStyleDelta tileStyle,
  }) {
    final selectable = !ayahIntent || moshaf.hasTiming;
    final tags = moshafTags(moshaf.name);
    final primary = moshafPrimaryLabel(moshaf, l10n);
    final subtitle = selectable
        ? moshafSubtitle(moshaf: moshaf, tags: tags, l10n: l10n)
        : l10n.quranReciterSurahOnly;

    return FSelectTile.suffix(
      style: tileStyle,
      value: ReciterMoshafKey(reciter.id, moshaf.id),
      enabled: selectable,
      checkedIcon: Icon(FLucideIcons.check, size: 16, color: colors.primary),
      uncheckedIcon: const Icon(
        FLucideIcons.check,
        size: 16,
        color: Colors.transparent,
      ),
      prefix: MoshafPrefix(style: tags.style),
      title: Text(primary, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: subtitle == null ? null : Text(subtitle),
      details: MoshafMetaRow(
        moshaf: moshaf,
        downloaded: downloadedKeys.contains((reciter.id, moshaf.id)),
      ),
    );
  }
}
