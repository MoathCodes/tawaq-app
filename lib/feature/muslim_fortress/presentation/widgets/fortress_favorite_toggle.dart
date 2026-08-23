import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/fortress_screen_settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Bookmark control shared by the browse sidebar and chapter detail header.
class FortressFavoriteToggle extends ConsumerWidget {
  /// Creates a chapter favorite toggle.
  const new({
    required this.chapterId,
    this.iconSize = 18,
    super.key,
  });

  /// Hisn chapter id to favorite.
  final int chapterId;

  /// Icon size for sidebar vs detail header layouts.
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final isFavorite = ref.watch(
      fortressScreenSettingsProvider.select(
        (v) => v.asData?.value.favoriteChapterIds.contains(chapterId) ?? false,
      ),
    );

    return MouseClick(
      onClick: () => ref
          .read(fortressScreenSettingsProvider.notifier)
          .toggleFavorite(chapterId),
      semanticsLabel: l10n.fortressFavorites,
      child: FTooltip(
        tipBuilder: (_, _) => Text(l10n.fortressFavorites),
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Icon(
              isFavorite ? FLucideIcons.bookmarkCheck : FLucideIcons.bookmark,
              size: iconSize,
              semanticLabel: l10n.fortressFavorites,
              color: isFavorite
                  ? theme.colors.primary
                  : theme.colors.mutedForeground,
              fill: isFavorite ? 1.0 : 0.0,
            ),
          ),
        ),
      ),
    );
  }
}
