import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_fake_hadith.dart';
import 'package:tawaq/theme/theme.dart';

/// Dialog listing known weak and fabricated hadith warnings from Hisn.
class FortressFakeHadithDialog extends StatelessWidget {
  /// Creates the dialog.
  const FortressFakeHadithDialog({
    required this.entries,
    super.key,
  });

  /// Fake/weak hadith entries to display.
  final List<FortressFakeHadith> entries;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;

    return Semantics(
      role: SemanticsRole.alertDialog,
      scopesRoute: true,
      namesRoute: true,
      label: l10n.fortressFakeHadithGuide,
      child: FDialog(
        title: Text(l10n.fortressFakeHadithGuide),
        body: SizedBox(
          width: 640,
          height: 480,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                role: SemanticsRole.alert,
                container: true,
                label: l10n.fortressFakeHadithIntro,
                child: FAlert(
                  icon: Icon(FLucideIcons.info, color: colors.primary),
                  title: Text(l10n.fortressFakeHadithIntro),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: colors.secondary.withAlpha(80),
                      borderRadius: theme.radii.md,
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            FBadge(
                              child: Text(
                                entry.darga,
                                style: theme.typography.xs.copyWith(
                                  color: colors.destructive,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '#${entry.id}',
                              style: theme.typography.xs.copyWith(
                                color: colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          entry.text,
                          style: theme.typography.sm.copyWith(height: 1.7),
                        ),
                        if (entry.source.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            entry.source,
                            style: theme.typography.xs.copyWith(
                              color: colors.mutedForeground,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
        actions: [
          FButton(
            onPress: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}

/// Opens the fake-hadith reference dialog.
///
/// [context] is the host used to present the modal.
/// [entries] is usually loaded from the fake-hadith warnings provider.
Future<void> showFortressFakeHadithDialog(
  BuildContext context, {
  required List<FortressFakeHadith> entries,
}) {
  return showFDialog<void>(
    context: context,
    builder: (context, style, animation) =>
        FortressFakeHadithDialog(entries: entries),
  );
}
