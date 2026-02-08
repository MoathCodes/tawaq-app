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
import 'package:hasanat/feature/prayer/domain/models/prayer_card_model.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_images.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_card/prayer_card_provider.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/hero_header/hero_time_square.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/hero_header/hijri_date_pill.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/hero_header/status_selector_button.dart';
import 'package:hasanat/theme/theme.dart';

/// Hero header showing current prayer info with gradient background.
class PrayerHeroHeader extends ConsumerWidget {
  /// Creates a [PrayerHeroHeader] instance.
  const PrayerHeroHeader({super.key});

  /// Border radius for the hero card.
  static const kBorderRadius = BorderRadius.all(Radius.circular(16));

  /// Returns a gradient color pair for each prayer.
  /// The first color is the primary (lighter), the second is the accent
  /// (darker).
  static (Color, Color) getPrayerGradient(Prayer prayer) {
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
        data: (data) => HeroContent(data: data, theme: theme),
        error: (e, _) => FAlert(
          title: Text(context.l10n.errorOccurredWhile('Loading Prayer Info')),
          subtitle: Text(e.toString()),
        ),
        loading: () => FSkeletonizer(
          child: HeroContent(data: PrayerCardInfo.empty(), theme: theme),
        ),
      ),
    );
  }
}

/// The main content of the hero header card.
class HeroContent extends ConsumerWidget {
  /// Creates a [HeroContent].
  const HeroContent({required this.data, required this.theme, super.key});

  /// The prayer card data to display.
  final PrayerCardInfo data;

  /// The current theme data.
  final FThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hijriDate = ref.watch(hijriClockProvider);

    final (gradientStart, gradientEnd) = PrayerHeroHeader.getPrayerGradient(
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
        borderRadius: PrayerHeroHeader.kBorderRadius,
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
                    HijriDatePill(hijriDate: hijriDate),
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
                // Adhan/Iqamah boxes
                Row(
                  children: [
                    HeroTimeSquare(
                      time: data.adhanTime,
                      label: data.prayer.isObligatory
                          ? context.l10n.adhan
                          : null,
                    ),
                    if (data.showIqamah) ...[
                      const SizedBox(width: AppSpacing.lg),
                      HeroTimeSquare(
                        time: data.iqamahTime,
                        label: context.l10n.iqamah,
                      ),
                    ],
                    const Spacer(),
                    StatusSelectorButton(
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
