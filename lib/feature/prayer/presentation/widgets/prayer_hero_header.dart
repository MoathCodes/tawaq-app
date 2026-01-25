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

  static Color _getPrayerColor(Prayer prayer) {
    return switch (prayer) {
      Prayer.fajr => Colors.blueGrey.shade400,
      Prayer.sunrise => Colors.orange.shade400,
      Prayer.dhuhr => Colors.lightBlue.shade400,
      Prayer.asr => Colors.amber.shade600,
      Prayer.maghrib => Colors.deepOrange.shade400,
      Prayer.isha => Colors.indigo.shade400,
      _ => Colors.teal.shade400,
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
          child: _HeroContent(data: _MockData(), theme: theme),
        ),
      ),
    );
  }
}

class _MockData implements PrayerCardInfo {
  @override
  String get adhanTime => '--:--';
  @override
  String get iqamahTime => '--:--';
  @override
  Prayer get prayer => Prayer.fajr;
  @override
  String get time => 'Loading...';
  @override
  $PrayerCardInfoCopyWith<PrayerCardInfo> get copyWith =>
      throw UnimplementedError();
}

class _HeroContent extends ConsumerWidget {
  const _HeroContent({required this.data, required this.theme});

  final PrayerCardInfo data;
  final FThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hijriDate = ref.watch(hijriClockProvider);

    final prayerColor = PrayerHeroHeader._getPrayerColor(data.prayer);
    final primary = theme.colors.primary;

    return Container(
      height: 260.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary,
            Color.lerp(primary, prayerColor, 0.4) ?? primary,
          ],
        ),
        borderRadius: PrayerHeroHeader._kBorderRadius,
      ),
      child: Stack(
        children: [
          // Watermark Icon
          Positioned(
            right: -20,
            bottom: -40,
            child: Transform.rotate(
              angle: -0.2,
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
                _PrayerNameSection(data: data),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${context.l10n.nextPrayer}: ${data.time}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16.sp,
                  ),
                ),
                const Spacer(),
                const SizedBox(height: AppSpacing.lg),
                // Status Button
                SizedBox(
                  width: double.infinity,
                  child: _StatusSelectorButton(prayer: data.prayer),
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
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

class _PrayerNameSection extends StatelessWidget {
  const _PrayerNameSection({required this.data});

  final PrayerCardInfo data;

  @override
  Widget build(BuildContext context) {
    return Text(
      data.prayer.getLocaleName(context.l10n),
      style: TextStyle(
        color: Colors.white,
        fontSize: 36.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _StatusSelectorButton extends ConsumerWidget {
  const _StatusSelectorButton({required this.prayer});

  final Prayer prayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completions = ref.watch(prayerCompletionProvider);
    final currentStatus = completions.maybeWhen(
      data: (list) {
        final match = list.where((c) => c.prayer == prayer).firstOrNull;
        return match?.status ?? CompletionStatus.none;
      },
      orElse: () => CompletionStatus.none,
    );

    return FPopoverMenu(
      menu: [
        FItemGroup(
          children: CompletionStatus.values
              .where((v) => v != CompletionStatus.none)
              .map(
                (e) => FItem(
                  title: Text(e.getLocaleName(context.l10n)),
                  prefix: Icon(e.getIcon(), color: e.getBadgeColor()),
                  onPress: () {
                    ref
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
      builder: (context, controller, _) => MouseClick(
        onClick: controller.toggle,
        child: Container(
          width: 140.w,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (currentStatus != CompletionStatus.none) ...[
                Icon(
                  currentStatus.getIcon(),
                  color: Colors.white,
                  size: 16.sp,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  currentStatus.getLocaleName(context.l10n),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                Text(
                  context.l10n.logPrayerStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// _PrayerIconDecoration removed as part of refactor
