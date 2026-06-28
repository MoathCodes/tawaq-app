import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/domain/services/reciter_tags.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// Stable identity for a reciter + moshaf pair in [FSelectTileGroup].
@immutable
class ReciterMoshafKey {
  /// Creates a reciter/moshaf key.
  const ReciterMoshafKey(this.reciterId, this.moshafId);

  /// Reciter catalog id.
  final int reciterId;

  /// Moshaf catalog id.
  final int moshafId;

  @override
  bool operator ==(Object other) =>
      other is ReciterMoshafKey &&
      other.reciterId == reciterId &&
      other.moshafId == moshafId;

  @override
  int get hashCode => Object.hash(reciterId, moshafId);
}

/// Tile style for reciter rows in the picker.
const reciterTileStyle = FItemStyleDelta.delta(
  contentStyle: .delta(
    titleSpacing: 2,
    suffixedPadding: .value(
      EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    ),
    prefixIconSpacing: AppSpacing.sm,
  ),
);

/// Tile style for inline/detail riwayah rows.
const riwayahTileStyle = FItemStyleDelta.delta(
  contentStyle: .delta(
    titleSpacing: 2,
    suffixedPadding: .value(
      EdgeInsetsDirectional.only(
        start: AppSpacing.xl,
        end: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
    ),
    prefixIconSpacing: AppSpacing.sm,
  ),
);

/// Primary label for a moshaf row.
String moshafPrimaryLabel(Moshaf moshaf, AppLocalizations l10n) {
  final tags = moshafTags(moshaf.name);
  final parts = <String>[];
  if (tags.riwayah != null) parts.add(tags.riwayah!);
  if (tags.style != null) {
    parts.add(
      switch (tags.style!) {
        RecitationStyle.murattal => l10n.quranReciterStyleMurattal,
        RecitationStyle.mujawwad => l10n.quranReciterStyleMujawwad,
      },
    );
  }
  return parts.isNotEmpty ? parts.join(' · ') : moshaf.name;
}

/// Secondary label for a moshaf row when it differs from the raw name.
String? moshafSubtitle({
  required Moshaf moshaf,
  required ({RecitationStyle? style, String? riwayah}) tags,
  required AppLocalizations l10n,
}) {
  final primary = moshafPrimaryLabel(moshaf, l10n);
  if (primary != moshaf.name) return moshaf.name;
  return null;
}

/// Icon-only meta badge with tooltip for reciter/moshaf rows.
class ReciterMetaIcon extends StatelessWidget {
  /// Creates a meta icon.
  const ReciterMetaIcon({
    required this.message,
    required this.icon,
    required this.color,
    this.size = 13,
    super.key,
  });

  /// Tooltip and semantics label.
  final String message;

  /// Icon glyph.
  final IconData icon;

  /// Icon color.
  final Color color;

  /// Icon size.
  final double size;

  @override
  Widget build(BuildContext context) {
    return FTooltip(
      tipBuilder: (_, _) => Text(message),
      child: Semantics(
        label: message,
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}

/// Prefix icon for a moshaf row based on recitation style.
class MoshafPrefix extends StatelessWidget {
  /// Creates a moshaf prefix icon.
  const MoshafPrefix({required this.style, super.key});

  /// Parsed recitation style from the moshaf name.
  final RecitationStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final (icon, tint) = switch (style) {
      RecitationStyle.mujawwad => (FLucideIcons.sparkles, colors.primary),
      RecitationStyle.murattal => (
        FLucideIcons.audioLines,
        colors.mutedForeground,
      ),
      null => (FLucideIcons.bookOpen, colors.mutedForeground),
    };

    return Icon(icon, size: 16, color: tint);
  }
}

/// Download/timing meta icons for a reciter header row.
class ReciterHeaderMeta extends StatelessWidget {
  /// Creates reciter header meta icons.
  const ReciterHeaderMeta({
    required this.reciter,
    required this.downloadedKeys,
    super.key,
  });

  /// Reciter being displayed.
  final Reciter reciter;

  /// Set of downloaded (reciterId, moshafId) pairs.
  final Set<(int, int)> downloadedKeys;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = context.theme.colors.mutedForeground;
    final downloaded = reciter.moshaf.any(
      (m) => downloadedKeys.contains((reciter.id, m.id)),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs,
      children: [
        if (reciter.hasTiming)
          ReciterMetaIcon(
            message: l10n.quranReciterTimed,
            icon: FLucideIcons.audioLines,
            color: muted,
          ),
        if (downloaded)
          ReciterMetaIcon(
            message: l10n.quranReciterFilterDownloaded,
            icon: FLucideIcons.download,
            color: muted,
          ),
      ],
    );
  }
}

/// Download/timing meta icons for a moshaf row.
class MoshafMetaRow extends StatelessWidget {
  /// Creates moshaf meta icons.
  const MoshafMetaRow({
    required this.moshaf,
    required this.downloaded,
    super.key,
  });

  /// Moshaf being displayed.
  final Moshaf moshaf;

  /// Whether this moshaf is cached offline.
  final bool downloaded;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = context.theme.colors.mutedForeground;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs,
      children: [
        if (moshaf.hasTiming)
          ReciterMetaIcon(
            message: l10n.quranReciterTimed,
            icon: FLucideIcons.audioLines,
            color: muted,
            size: 12,
          ),
        if (downloaded)
          ReciterMetaIcon(
            message: l10n.quranReciterFilterDownloaded,
            icon: FLucideIcons.hardDriveDownload,
            color: muted,
            size: 12,
          ),
      ],
    );
  }
}
