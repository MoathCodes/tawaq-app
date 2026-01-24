import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/hooks/hooks.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/core/widgets/icon_badge.dart';
import 'package:hasanat/core/widgets/mouse_click.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_images.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_tracker_card_model.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// A card widget that displays prayer completion status and allows changing it.
class TrackerCompletionCard extends HookConsumerWidget {
  /// Creates a [TrackerCompletionCard] instance.
  const TrackerCompletionCard({
    required this.cardData,
    required this.completionTime,
    this.onCompletionChanged,
    super.key,
  });

  final PrayerTrackerCardModel cardData;
  final DateTime completionTime;
  final void Function(PrayerCompletion)? onCompletionChanged;

  static const _animDuration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:isHovered, :setHovered) = useHoverState();
    final isDisabled = useState(!cardData.isTimePassed);
    final status = useState(
      cardData.completion?.status ?? CompletionStatus.none,
    );

    useEffect(() {
      isDisabled.value = !cardData.isTimePassed;
      status.value = cardData.completion?.status ?? CompletionStatus.none;
      return null;
    }, [cardData]);

    void handleClick(CompletionStatus v) {
      status.value = v;
      onCompletionChanged?.call(
        PrayerCompletion(
          id: cardData.completion?.id,
          status: v,
          prayer: cardData.prayer,
          completionTime: completionTime,
        ),
      );
    }

    final theme = FTheme.of(context);
    final colors = theme.colors;

    return FPopoverMenu(
      menu: [
        FItemGroup(
          children: CompletionStatus.values
              .where((v) => v != .none)
              .map(
                (e) => FItem(
                  title: Text(e.getLocaleName(context.l10n)),
                  prefix: Icon(e.getIcon(), color: e.getBadgeColor()),
                  onPress: () => handleClick(e),
                ),
              )
              .toList(),
        ),
      ],
      builder: (_, controller, _) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 200.h),
        child: MouseClick(
          disabled: isDisabled.value,
          onClick: controller.toggle,
          onExit: (_) => setHovered(value: false),
          onHover: (_) => setHovered(value: true),
          child: AnimatedOpacity(
            duration: _animDuration,
            opacity: isDisabled.value ? 0.5 : 1.0,
            curve: Curves.easeInOut,
            onEnd: () {
              if (cardData.isTimePassed) setHovered(value: false);
            },
            child: AnimatedScale(
              duration: _animDuration,
              scale: isHovered ? 1.05 : 1.0,
              curve: Curves.bounceInOut,
              child: AnimatedContainer(
                duration: _animDuration,
                curve: Curves.easeInOut,
                width: 250.w,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.cardStyle.decoration.color,
                  border: Border.all(color: colors.secondary.withAlpha(45)),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isHovered
                      ? [
                          BoxShadow(
                            color: colors.secondaryForeground.withAlpha(60),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  spacing: AppSpacing.xs,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Builder(
                          builder: (ctx) {
                            final w = 46.w;
                            final h = 46.h;
                            final dpr = MediaQuery.of(ctx).devicePixelRatio;
                            return Container(
                              width: w,
                              height: h,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: ResizeImage(
                                    AssetImage(cardData.prayer.imagePath),
                                    width: (w * dpr).round(),
                                    height: (h * dpr).round(),
                                  ),
                                  fit: BoxFit.cover,
                                  alignment: cardData.prayer.alignment,
                                ),
                                borderRadius: context.theme.radii.md,
                              ),
                            );
                          },
                        ),
                        _StatusChip(status: status.value),
                      ],
                    ),
                    Text(
                      cardData.prayer.getLocaleName(context.l10n),
                      style: context.theme.typography.lg.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      cardData.adhan,
                      style: context.theme.typography.xl.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    Text(
                      cardData.subtitle,
                      style: context.theme.typography.sm.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final CompletionStatus status;

  @override
  Widget build(BuildContext context) {
    return HookConsumer(
      builder: (_, ref, _) {
        final isDark =
            ref.watch(themeProvider).value?.themeMode == ThemeMode.dark;
        final style = context.theme.typography.sm.copyWith(color: Colors.white);

        Color bgColor(Color light, Color dark) => isDark ? dark : light;

        return switch (status) {
          CompletionStatus.jamaah => IconBadge(
            style: (s) => s.copyWith(
              decoration: s.decoration.copyWith(
                color: bgColor(Colors.green.shade600, Colors.green.shade900),
              ),
            ),
            icon: const Icon(FIcons.users, size: 16, color: Colors.white),
            label: Text(status.getLocaleName(context.l10n), style: style),
          ),
          CompletionStatus.onTime => IconBadge(
            style: (s) => s.copyWith(
              decoration: s.decoration.copyWith(
                color: bgColor(Colors.yellow.shade600, Colors.yellow.shade900),
              ),
            ),
            icon: const Icon(FIcons.checkCheck, size: 16, color: Colors.white),
            label: Text(status.getLocaleName(context.l10n), style: style),
          ),
          CompletionStatus.late => IconBadge(
            style: (s) => s.copyWith(
              decoration: s.decoration.copyWith(
                color: bgColor(Colors.orange.shade600, Colors.orange.shade900),
              ),
            ),
            icon: const Icon(FIcons.clock, size: 16, color: Colors.white),
            label: Text(status.getLocaleName(context.l10n), style: style),
          ),
          CompletionStatus.missed => IconBadge(
            style: (s) => s.copyWith(
              decoration: s.decoration.copyWith(
                color: bgColor(Colors.red.shade600, Colors.red.shade900),
              ),
            ),
            icon: const Icon(FIcons.circleX, size: 16, color: Colors.white),
            label: Text(status.getLocaleName(context.l10n), style: style),
          ),
          CompletionStatus.none => const SizedBox.shrink(),
        };
      },
    );
  }
}
