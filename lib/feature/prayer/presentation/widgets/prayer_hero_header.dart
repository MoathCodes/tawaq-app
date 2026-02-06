import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/hijri_provider.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';
import 'package:hasanat/core/widgets/f_skeletonizer.dart';
import 'package:hasanat/core/widgets/mouse_click.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_card_model.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_images.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_card/prayer_card_provider.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:hasanat/theme/theme.dart';

/// Hero header showing current prayer info with gradient background.
class PrayerHeroHeader extends ConsumerWidget {
  /// Creates a [PrayerHeroHeader] instance.
  const PrayerHeroHeader({super.key});

  static const _kBorderRadius = BorderRadius.all(Radius.circular(16));

  /// Returns a gradient color pair for each prayer.
  /// The first color is the primary (lighter), the second is the accent (darker).
  static (Color, Color) _getPrayerGradient(Prayer prayer) {
    return switch (prayer) {
      Prayer.fajr => (
        const Color(0xFF5C6BC0), // Indigo/blue twilight
        const Color(0xFF303F9F), // Darker indigo
      ),
      Prayer.sunrise => (
        const Color(0xFFFF8A65), // Soft orange
        const Color(0xFFE64A19), // Deep orange
      ),
      Prayer.dhuhr => (
        const Color(0xFF4FC3F7), // Light sky blue
        const Color(0xFF0288D1), // Deep blue
      ),
      Prayer.asr => (
        const Color(0xFFFFB74D), // Warm amber
        const Color(0xFFF57C00), // Deep amber
      ),
      Prayer.maghrib => (
        const Color(0xFFFF7043), // Sunset orange
        const Color(0xFFD84315), // Deep burnt orange
      ),
      Prayer.isha => (
        const Color(0xFF7986CB), // Soft indigo
        const Color(0xFF3949AB), // Deep indigo
      ),
      _ => (
        const Color(0xFF4DB6AC), // Teal
        const Color(0xFF00897B), // Deep teal
      ),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardStream = ref.watch(prayerCardProvider);
    final theme = FTheme.of(context);

    return StaticCard(
      backgroundColor: Colors.transparent,
      borderColor: Colors.transparent,
      padding: EdgeInsets.zero,
      child: cardStream.when(
        data: (data) => _HeroContent(data: data, theme: theme),
        error: (e, _) => FAlert(
          title: Text(context.l10n.errorOccurredWhile('Loading Prayer Info')),
          subtitle: Text(e.toString()),
        ),
        loading: () => FSkeletonizer(
          child: _HeroContent(data: PrayerCardInfo.empty(), theme: theme),
        ),
      ),
    );
  }
}

class _HeroContent extends ConsumerWidget {
  const _HeroContent({required this.data, required this.theme});

  final PrayerCardInfo data;
  final FThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hijriDate = ref.watch(hijriClockProvider);

    final (gradientStart, gradientEnd) = PrayerHeroHeader._getPrayerGradient(
      data.prayer,
    );

    // Flip gradient direction based on text direction (RTL vs LTR)
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Container(
      height: 260.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isRtl ? Alignment.topLeft : Alignment.topRight,
          end: isRtl ? Alignment.bottomRight : Alignment.bottomLeft,
          colors: [gradientStart, gradientEnd],
        ),
        borderRadius: PrayerHeroHeader._kBorderRadius,
      ),
      child: Stack(
        children: [
          // Watermark Icon
          Positioned(
            right: isRtl ? null : -20,
            left: isRtl ? -20 : null,
            bottom: -40,
            child: Transform.rotate(
              angle: isRtl ? 0.2 : -0.2,
              child: Icon(
                data.prayer.icon,
                size: 200.sp,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Date)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _HijriDatePill(hijriDate: hijriDate),
                  ],
                ),
                const Spacer(),
                // Prayer Info
                Text(
                  data.prayer.getLocaleName(context.l10n),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${context.l10n.nextPrayer}: ${data.time}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 18.sp,
                  ),
                ),
                const Spacer(),
                // Adhan/Iqamah boxes - larger and aligned left
                Row(
                  children: [
                    _TimeSquare(
                      time: data.adhanTime,
                      label: data.prayer.isObligatory
                          ? context.l10n.adhan
                          : null,
                    ),
                    if (data.showIqamah) ...[
                      const SizedBox(width: AppSpacing.lg),
                      _TimeSquare(
                        time: data.iqamahTime,
                        label: context.l10n.iqamah,
                      ),
                    ],
                    const Spacer(),
                    _StatusSelectorButton(
                      prayer: data.prayer,
                      canSetStatus: data.canSetStatus,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HijriDatePill extends StatelessWidget {
  const _HijriDatePill({required this.hijriDate});

  final AsyncValue<String> hijriDate;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colors.background.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FIcons.calendar,
            color: Colors.white.withValues(alpha: 0.8),
            size: 14.sp,
          ),
          const SizedBox(width: AppSpacing.xs),
          switch (hijriDate) {
            AsyncData<String>(:final value) => Text(
              value,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12.sp,
              ),
            ),
            _ => Text(
              '...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12.sp,
              ),
            ),
          },
        ],
      ),
    );
  }
}

class _TimeSquare extends StatelessWidget {
  const _TimeSquare({required this.time, required this.label});

  final String time;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: theme.colors.background.withValues(alpha: 0.2),
        borderRadius: context.theme.radii.md,
        border: Border.all(
          color: theme.colors.border.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null)
            Text(
              label!.toUpperCase(),
              style: context.theme.typography.xs.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          const SizedBox(height: 6),
          Text(
            time,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusSelectorButton extends ConsumerWidget {
  const _StatusSelectorButton({
    required this.prayer,
    required this.canSetStatus,
  });

  final Prayer prayer;
  final bool canSetStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      prayerCompletionProvider.select(
        (value) => value.value
            ?.firstWhere(
              (c) => c.prayer == prayer,
              orElse: () => PrayerCompletion(
                prayer: prayer,
                status: CompletionStatus.none,
                completionTime: DateTime.now(),
                id: null,
              ),
            )
            .status,
      ),
    );

    return canSetStatus
        ? FPopoverMenu(
            menu: [
              FItemGroup(
                children: CompletionStatus.values
                    .where((v) => v != CompletionStatus.none)
                    .map(
                      (e) => FItem(
                        title: Text(e.getLocaleName(context.l10n)),
                        prefix: Icon(e.getIcon(), color: e.getBadgeColor()),
                        onPress: () async {
                          await ref
                              .read(prayerCompletionProvider.notifier)
                              .addOrUpdateCompletion(
                                PrayerCompletion(
                                  id: null,
                                  status: e,
                                  prayer: prayer,
                                  completionTime: DateTime.now(),
                                ),
                              );
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
            builder: (context, controller, _) {
              final isSet = status != CompletionStatus.none && status != null;
              final theme = FTheme.of(context);
              return MouseClick(
                onClick: controller.toggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSet
                        ? theme.colors.secondary
                        : theme.colors.background.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSet
                          ? theme.colors.secondary
                          : theme.colors.border.withValues(alpha: 0.1),
                    ),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSet) ...[
                          Icon(
                            status.getIcon(),
                            color: theme.colors.secondaryForeground,
                            size: 16.sp,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            status.getLocaleName(context.l10n),
                            style: TextStyle(
                              color: theme.colors.secondaryForeground,
                              fontWeight: FontWeight.w700,
                              fontSize: 14.sp,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Icon(
                            FIcons.chevronDown,
                            color: theme.colors.secondaryForeground,
                            size: 14.sp,
                          ),
                        ] else ...[
                          Text(
                            context.l10n.logPrayerStatus,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          )
        : const SizedBox.shrink();
  }
}
