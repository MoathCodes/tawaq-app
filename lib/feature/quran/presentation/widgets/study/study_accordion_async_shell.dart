import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/theme/theme.dart';

/// Shared loading, error, and animated content shell for study accordions.
class StudyAccordionAsyncShell<T> extends StatelessWidget {
  /// Creates a study accordion async shell.
  const StudyAccordionAsyncShell({
    required this.asyncValue,
    required this.header,
    required this.contentKey,
    required this.errorMessage,
    required this.emptyMessage,
    required this.contentBuilder,
    super.key,
  });

  /// Async value driving the shell state.
  final AsyncValue<T> asyncValue;

  /// Source selector or other pinned header above accordion body content.
  final Widget header;

  /// Key for [AnimatedSwitcher] when content is available.
  final Object contentKey;

  /// Message shown when [asyncValue] fails.
  final String errorMessage;

  /// Message shown when [asyncValue] succeeds with a null payload.
  final String emptyMessage;

  /// Builds the loaded accordion body for non-null [data].
  final Widget Function(T data) contentBuilder;

  Widget _messagePlaceholder(FTypography typography, FColors colors, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Text(
        message,
        style: typography.body.sm.copyWith(color: colors.mutedForeground),
      ),
    );
  }

  Widget _statusColumn({
    required FTypography typography,
    required FColors colors,
    required String message,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: AppSpacing.md),
        _messagePlaceholder(typography, colors, message),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;

    return asyncValue.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: AppSpacing.md),
          const FCircularProgress(),
        ],
      ),
      error: (_, _) => _statusColumn(
        typography: typography,
        colors: colors,
        message: errorMessage,
      ),
      data: (data) {
        if (data == null) {
          return _statusColumn(
            typography: typography,
            colors: colors,
            message: emptyMessage,
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child:
              Padding(
                    key: ValueKey(contentKey),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header,
                        const SizedBox(height: AppSpacing.lg),
                        contentBuilder(data),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 250.ms, curve: Curves.easeOut)
                  .slideY(
                    begin: 0.02,
                    end: 0,
                    duration: 250.ms,
                    curve: Curves.easeOut,
                  ),
        );
      },
    );
  }
}
