import 'dart:math' as math;

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/presentation/models/prayer_images.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_card/prayer_card_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/hero_header/hero_time_square.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/hero_header/hijri_date_pill.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/hero_header/status_selector_button.dart';
import 'package:tawaq/theme/theme.dart';

/// Hero header showing current prayer info with gradient background.
class PrayerHeroHeader extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return const HeroContent();
  }
}

/// The main content of the hero header card.
class HeroContent extends ConsumerWidget {
  /// Creates a [HeroContent].
  const HeroContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayLoading = ref.watch(prayerDayIsLoadingProvider);

    if (dayLoading) {
      return Semantics(
        label: context.l10n.loadingSchedule,
        child: const FSkeletonizer(
          child: _HeroBody(),
        ),
      );
    }

    return const _HeroBody();
  }
}

class _HeroBody extends ConsumerWidget {
  const _HeroBody();

  static const _minHeight = 200.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final prayer = ref.watch(
      prayerCardStaticProvider.select((card) => card.prayer),
    );
    final showIqamah = ref.watch(
      prayerCardStaticProvider.select((card) => card.showIqamah),
    );
    final (gradientStart, gradientEnd) = PrayerHeroHeader.getPrayerGradient(
      prayer,
    );

    // Flip gradient direction based on text direction (RTL vs LTR)
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoints = theme.breakpoints;
        final width = constraints.maxWidth;
        // Stack the bottom row when the main column is narrow (e.g. horizontal
        // prayer layout gives ~480–720 px to the hero column).
        final timeSquareDensity = _resolveTimeSquareDensity(
          width: width,
          breakpoints: breakpoints,
          showIqamah: showIqamah,
        );
        final stackBottomRow = width < breakpoints.lg;
        final watermarkSize = math.min(160, width * 0.32).toDouble();

        return Container(
          clipBehavior: Clip.antiAlias,
          constraints: const BoxConstraints(minHeight: _minHeight),
          decoration: BoxDecoration(
            borderRadius: PrayerHeroHeader.kBorderRadius,
            gradient: LinearGradient(
              begin: isRtl ? Alignment.topLeft : Alignment.topRight,
              end: isRtl ? Alignment.bottomRight : Alignment.bottomLeft,
              colors: [gradientStart, gradientEnd],
            ),
          ),
          child: Stack(
            children: [
              // Watermark Icon — kept inside card bounds
              Positioned(
                right: isRtl ? null : AppSpacing.lg,
                left: isRtl ? AppSpacing.lg : null,
                bottom: AppSpacing.md,
                child: ExcludeSemantics(
                  child: Transform.rotate(
                    angle: isRtl ? 0.2 : -0.2,
                    child: Icon(
                      prayer.icon,
                      size: watermarkSize,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header (Date)
                    const Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: HijriDatePill(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _HeroPrayerTitle(),
                    const SizedBox(height: AppSpacing.xs),
                    const _HeroNextPrayerLine(),
                    const SizedBox(height: AppSpacing.lg),
                    // Adhan/Iqamah boxes + status
                    if (stackBottomRow)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: AppSpacing.lg,
                            runSpacing: AppSpacing.md,
                            children: [
                              _HeroAdhanTimeSquare(
                                density: timeSquareDensity,
                              ),
                              _HeroIqamahTimeSquare(
                                density: timeSquareDensity,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: StatusSelectorButton(),
                          ),
                        ],
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _HeroAdhanTimeSquare(
                            density: timeSquareDensity,
                          ),
                          _HeroIqamahTimeSquare(
                            density: timeSquareDensity,
                            leadingSpacing: true,
                          ),
                          const Spacer(),
                          const Flexible(
                            child: Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: StatusSelectorButton(),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static HeroTimeSquareDensity _resolveTimeSquareDensity({
    required double width,
    required FBreakpoints breakpoints,
    required bool showIqamah,
  }) {
    const normalMin = 112.0;
    const compactMin = 96.0;
    const ultraMin = 80.0;
    const statusReserve = 120.0;
    final squareCount = showIqamah ? 2 : 1;
    final squareSpacing = showIqamah ? AppSpacing.lg : 0.0;
    final squaresWidth = squareCount == 2
        ? normalMin + compactMin + squareSpacing
        : normalMin;

    if (width >= breakpoints.lg && width >= squaresWidth + statusReserve) {
      return HeroTimeSquareDensity.normal;
    }
    if (width >= breakpoints.sm) {
      final compactWidth = squareCount == 2
          ? compactMin * 2 + squareSpacing
          : compactMin;
      if (width >= compactWidth + statusReserve) {
        return HeroTimeSquareDensity.compact;
      }
    }
    final ultraWidth = squareCount == 2
        ? ultraMin * 2 + squareSpacing
        : ultraMin;
    if (width >= ultraWidth) {
      return HeroTimeSquareDensity.ultraCompact;
    }
    return HeroTimeSquareDensity.ultraCompact;
  }
}

class _HeroPrayerTitle extends ConsumerWidget {
  const _HeroPrayerTitle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final prayer = ref.watch(
      prayerCardStaticProvider.select((card) => card.prayer),
    );

    return Text(
      prayer.getLocaleName(l10n),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.typography.body.xl4.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _HeroNextPrayerLine extends ConsumerWidget {
  const _HeroNextPrayerLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final time = ref.watch(prayerCardCountdownProvider);

    return Text(
      '${l10n.nextPrayer}: $time',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.typography.body.lg.copyWith(
        color: Colors.white.withValues(alpha: 0.9),
      ),
    );
  }
}

class _HeroAdhanTimeSquare extends ConsumerWidget {
  const _HeroAdhanTimeSquare({required this.density});

  final HeroTimeSquareDensity density;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final (adhanTime, prayer) = ref.watch(
      prayerCardStaticProvider.select((c) => (c.adhanTime, c.prayer)),
    );

    return HeroTimeSquare(
      time: adhanTime,
      label: prayer.isObligatory ? l10n.adhan : null,
      density: density,
    );
  }
}

class _HeroIqamahTimeSquare extends ConsumerWidget {
  const _HeroIqamahTimeSquare({
    required this.density,
    this.leadingSpacing = false,
  });

  final HeroTimeSquareDensity density;
  final bool leadingSpacing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showIqamah = ref.watch(
      prayerCardStaticProvider.select((card) => card.showIqamah),
    );
    if (!showIqamah) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final iqamahTime = ref.watch(
      prayerCardStaticProvider.select((card) => card.iqamahTime),
    );

    final square = HeroTimeSquare(
      time: iqamahTime,
      label: l10n.iqamah,
      density: density,
    );

    if (!leadingSpacing) {
      return square;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: AppSpacing.lg),
        square,
      ],
    );
  }
}
