import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Header shown in bookmarks view with a back-to-search affordance.
class HadithBookmarksHeader extends ConsumerWidget {
  /// Creates the bookmarks header.
  const HadithBookmarksHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final screenController = ref.read(hadithSessionControllerProvider.notifier);

    return Row(
      spacing: AppSpacing.sm,
      children: [
        FButton.icon(
          variant: FButtonVariant.ghost,
          onPress: () => unawaited(screenController.exitSpecificMode()),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.xs,
            children: [
              const Icon(FLucideIcons.chevronLeft, size: 16),
              Text(l10n.hadithBackToSearch),
            ],
          ),
        ),
        Text(
          l10n.bookmarks,
          style: theme.typography.body.lg.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
