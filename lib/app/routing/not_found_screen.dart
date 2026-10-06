import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/app/routing/route_provider.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/theme/theme.dart';

/// A screen that is displayed when a route is not found.
class NotFoundScreen extends StatelessWidget {
  /// Creates a not found screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return FScaffold(
      child: Center(
        child: SingleChildScrollView(
          padding: const .all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Container(
                    padding: const .all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: theme.colors.destructive.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      FLucideIcons.bug,
                      size: 64,
                      color: theme.colors.destructive,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                Semantics(
                  header: true,
                  child: Text(
                    context.l10n.pageNotFound,
                    style: theme.typography.body.xl2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colors.foreground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                Text(
                  context.l10n.pageNotFoundDescription,
                  style: theme.typography.body.lg.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xxl),

                FButton(
                  onPress: () => const PrayerRoute().go(context),
                  prefix: const Icon(FLucideIcons.clock, size: 18),
                  child: Text(context.l10n.goToPrayerPage),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
