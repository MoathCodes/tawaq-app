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

  /// The data for the prayer card.
  final PrayerTrackerCardModel cardData;

  /// The time for which the completion is recorded.
  final DateTime completionTime;

  /// Callback when the completion status is changed.
  final void Function(PrayerCompletion prayerCompletion)? onCompletionChanged;

  static const Duration _animationDuration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:isHovered, :setHovered) = useHoverState();
    final isDisabled = useState(!cardData.isTimePassed);
    final completionStatus = useState(
      cardData.completion?.status ?? CompletionStatus.none,
    );

    // Sync state when cardData changes (equivalent to didUpdateWidget)
    useEffect(
      () {
        isDisabled.value = !cardData.isTimePassed;
        completionStatus.value =
            cardData.completion?.status ?? CompletionStatus.none;
        return null;
      },
      [cardData],
    );

    void handleClick(CompletionStatus value) {
      completionStatus.value = value;
      onCompletionChanged?.call(
        PrayerCompletion(
          id: cardData.completion?.id,
          status: value,
          prayer: cardData.prayer,
          completionTime: completionTime,
        ),
      );
    }

    final theme = FTheme.of(context);
    final colorScheme = theme.colors;
    return FPopoverMenu(
      menu: [
        FItemGroup(
          children: CompletionStatus.values
              .where((value) => value != .none)
              .map(
                (e) => FItem(
                  title: Text(
                    e.getLocaleName(context.l10n),
                  ),
                  prefix: Icon(e.getIcon(), color: e.getBadgeColor()),
                  onPress: () => handleClick(e),
                ),
              )
              .toList(),
        ),
      ],
      builder: (context, controller, child) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 200.h),
        child: MouseClick(
          disabled: isDisabled.value,
          onClick: controller.toggle,
          onExit: (event) => setHovered(value: false),
          onHover: (event) => setHovered(value: true),
          child: AnimatedOpacity(
            duration: _animationDuration,
            opacity: isDisabled.value ? 0.5 : 1.0,
            curve: Curves.easeInOut,
            onEnd: () {
              if (cardData.isTimePassed) {
                setHovered(value: false);
              }
            },
            child: AnimatedScale(
              duration: _animationDuration,
              scale: isHovered ? 1.05 : 1.0,
              curve: Curves.bounceInOut,
              child: AnimatedContainer(
                duration: _animationDuration,
                curve: Curves.easeInOut,
                width: 250.w,
                padding: const .all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.cardStyle.decoration.color,
                  border: Border.all(
                    color: colorScheme.secondary.withAlpha(45),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isHovered
                      ? [
                          BoxShadow(
                            color: colorScheme.secondaryForeground.withAlpha(
                              60,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: .start,
                  mainAxisAlignment: .spaceEvenly,
                  children: [
                    Row(
                      mainAxisAlignment: .spaceBetween,
                      children: [
                        Builder(
                          builder: (context) {
                            final w = 46.w;
                            final h = 46.h;
                            final dpr = MediaQuery.of(context).devicePixelRatio;
                            final provider = ResizeImage(
                              AssetImage(cardData.prayer.imagePath),
                              width: (w * dpr).round(),
                              height: (h * dpr).round(),
                            );
                            return Container(
                              width: w,
                              height: h,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: provider,
                                  fit: BoxFit.cover,
                                  alignment: cardData.prayer.alignment,
                                ),
                                borderRadius: context.theme.radii.md,
                              ),
                            );
                          },
                        ),
                        _StatusChip(status: completionStatus.value),
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
                        color: context.theme.colors.primary,
                      ),
                    ),
                    Text(
                      cardData.subtitle,
                      style: context.theme.typography.sm.copyWith(
                        color: context.theme.colors.mutedForeground,
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
    final style = context.theme.typography.sm.copyWith(color: Colors.white);
    return HookConsumer(
      builder: (context, ref, child) {
        final isDarkMode =
            ref.watch(themeProvider).value?.themeMode == ThemeMode.dark;
        final context = useContext();
        return switch (status) {
          CompletionStatus.jamaah => IconBadge(
            style: (p0) => p0.copyWith(
              decoration: p0.decoration.copyWith(
                color: isDarkMode
                    ? Colors.green.shade900
                    : Colors.green.shade600,
              ),
            ),
            icon: const Icon(FIcons.users, size: 16, color: Colors.white),
            label: Text(status.getLocaleName(context.l10n), style: style),
          ),
          CompletionStatus.onTime => IconBadge(
            style: (p0) => p0.copyWith(
              decoration: p0.decoration.copyWith(
                color: isDarkMode
                    ? Colors.yellow.shade900
                    : Colors.yellow.shade600,
              ),
            ),
            icon: const Icon(FIcons.checkCheck, size: 16, color: Colors.white),
            label: Text(status.getLocaleName(context.l10n), style: style),
          ),
          CompletionStatus.late => IconBadge(
            style: (p0) => p0.copyWith(
              decoration: p0.decoration.copyWith(
                color: isDarkMode
                    ? Colors.orange.shade900
                    : Colors.orange.shade600,
              ),
            ),
            icon: const Icon(FIcons.clock, size: 16, color: Colors.white),
            label: Text(status.getLocaleName(context.l10n), style: style),
          ),
          CompletionStatus.missed => IconBadge(
            style: (p0) => p0.copyWith(
              decoration: p0.decoration.copyWith(
                color: isDarkMode ? Colors.red.shade900 : Colors.red.shade600,
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
