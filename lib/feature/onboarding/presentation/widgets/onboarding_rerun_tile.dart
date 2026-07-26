import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/routing/route_provider.dart';
import 'package:tawaq/feature/onboarding/presentation/providers/onboarding_state_provider.dart';

/// Settings entry to re-run the onboarding flow.
class OnboardingRerunTile extends ConsumerWidget {
  /// Creates [OnboardingRerunTile].
  const OnboardingRerunTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return FTile(
      prefix: const Icon(FLucideIcons.sparkles),
      title: Text(l10n.onboardingRerunTitle),
      subtitle: Text(l10n.onboardingRerunSubtitle),
      suffix: const Icon(FLucideIcons.chevronRight),
      onPress: () async {
        final cleared = await ref
            .read(onboardingStateProvider.notifier)
            .reset();
        if (!cleared || !context.mounted) return;
        const OnboardingRoute().go(context);
      },
    );
  }
}
