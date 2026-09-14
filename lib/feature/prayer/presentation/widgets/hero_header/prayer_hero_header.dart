import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/prayer_extensions.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/prayer_calendar.dart';
import 'package:tawaq/feature/prayer/presentation/extensions/completion_status_ui.dart';
import 'package:tawaq/feature/prayer/presentation/provider/hijri_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_card/prayer_card_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completions_for_date_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/hero_header/prayer_hero_labels.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/prayer_semantics.dart';
import 'package:tawaq/theme/theme.dart';

/// Hero header showing the current or next prayer with a time-aware surface.
class PrayerHeroHeader extends ConsumerWidget {
  /// Creates a [PrayerHeroHeader] instance.
  const new({super.key});

  /// Border radius for the hero card.
  static const kBorderRadius = BorderRadius.all(Radius.circular(16));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(prayerDayIsLoadingProvider)) {
      return Semantics(
        label: context.l10n.loadingSchedule,
        child: const FSkeletonizer(child: _HeroBody()),
      );
    }

    return const _HeroBody();
  }
}

class _HeroBody extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final card = ref.watch(prayerCardStaticProvider);
    final dayKey = ref.watch(prayerCalendarDayKeyProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 600 ||
            MediaQuery.textScalerOf(context).scale(16) > 22;
        final identity = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              card.prayer.getLocaleName(l10n),
              style: theme.typography.body.xl3.copyWith(
                color: theme.colors.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: [
                _HeroScheduledTime(
                  time: card.adhanTime,
                  label: card.prayer.isObligatory ? l10n.adhan : null,
                ),
                if (card.showIqamah)
                  _HeroScheduledTime(time: card.iqamahTime, label: l10n.iqamah),
              ],
            ),
          ],
        );

        return Container(
          key: const ValueKey('prayer-hero-surface'),
          decoration: BoxDecoration(
            color: theme.colors.card,
            borderRadius: PrayerHeroHeader.kBorderRadius,
            border: Border.all(color: theme.colors.border),
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  _HeroStateLabel(prayer: card.prayer),
                  const _HeroHijriDatePill(),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (stacked) ...[
                identity,
                const SizedBox(height: AppSpacing.lg),
                _HeroCountdownLabel(prayer: card.prayer),
              ] else
                Row(
                  children: [
                    Expanded(flex: 5, child: identity),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                      flex: 4,
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: _HeroCountdownLabel(prayer: card.prayer),
                      ),
                    ),
                  ],
                ),
              if (card.canSetStatus && dayKey != 0) ...[
                const SizedBox(height: AppSpacing.lg),
                const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _HeroStatusPopover(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HeroScheduledTime extends StatelessWidget {
  const new({required this.time, this.label});

  final String time;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Semantics(
      label: PrayerSemantics.heroTimeSquare(time: time, caption: label),
      readOnly: true,
      excludeSemantics: true,
      child: Wrap(
        spacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (label != null)
            Text(
              label!,
              style: theme.typography.body.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          Text(
            time,
            textDirection: TextDirection.ltr,
            style: theme.typography.body.lg.copyWith(
              color: theme.colors.foreground,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Isolates the 1 Hz countdown so the hero chrome does not rebuild each tick.
class _HeroCountdownLabel extends ConsumerWidget {
  const new({required this.prayer});

  final Prayer prayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final isCountdown = ref.watch(
      prayerCardStaticProvider.select((card) => card.isCountdown),
    );
    final countdown = ref.watch(prayerCardCountdownProvider);
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: .center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            prayerCardDurationLabel(
              l10n: l10n,
              prayer: prayer,
              isCountdown: isCountdown,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.typography.body.sm.copyWith(
              color: theme.colors.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              countdown,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
              key: const ValueKey('prayer-hero-countdown'),
              style: theme.typography.body.xl3.copyWith(
                fontSize: 42,
                height: 1.2,
                color: theme.colors.primary,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStateLabel extends ConsumerWidget {
  const new({required this.prayer});

  final Prayer prayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final isCountdown = ref.watch(
      prayerCardStaticProvider.select((card) => card.isCountdown),
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        prayerCardStateLabel(
          l10n: l10n,
          prayer: prayer,
          isCountdown: isCountdown,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.typography.body.xs.copyWith(
          color: theme.colors.foreground,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _HeroHijriDatePill extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FTheme.of(context);
    final dateLabel = ref.watch(hijriClockProvider);

    return Semantics(
      label: dateLabel,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: theme.colors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(
                FLucideIcons.calendar,
                color: theme.colors.foreground,
                size: theme.typography.body.sm.fontSize,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                dateLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.body.xs.copyWith(
                  color: theme.colors.foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStatusPopover extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final (prayer, canSetStatus) = ref.watch(
      prayerCardStaticProvider.select((c) => (c.prayer, c.canSetStatus)),
    );
    final dayKey = ref.watch(prayerCalendarDayKeyProvider);
    if (!canSetStatus || dayKey == 0) {
      return const SizedBox.shrink();
    }
    // Pre-Fajr Isha is yesterday's slot — log against that completion day.
    // Select so 1 Hz ticks do not rebuild until fajr/day boundary.
    final ishaPreFajrDay = ref.watch(
      prayerDayProvider.select((asyncDay) {
        final day = asyncDay.value;
        if (day == null || !day.now.isBefore(day.timeline.fajrToday)) {
          return null;
        }
        final y = day.timeline.ishaYesterday;
        return DateTime(y.year, y.month, y.day);
      }),
    );
    final completionDay = prayer == Prayer.isha && ishaPreFajrDay != null
        ? ishaPreFajrDay
        : dateFromCalendarDayKey(dayKey);
    final status = ref.watch(
      completionStatusProvider(prayer, calendarDayKeyFromDate(completionDay)),
    );

    final menuTriggerLabel = PrayerSemantics.statusMenuTrigger(
      l10n: l10n,
      status: status,
    );

    return FPopoverMenu(
      menu: [
        FItemGroup(
          children: CompletionStatus.values
              .where((v) => v != CompletionStatus.none)
              .map(
                (e) => FItem(
                  title: Text(e.getLocaleName(l10n)),
                  prefix: Icon(
                    e.getIcon(),
                    color: e.getBadgeColor(theme.colors),
                  ),
                  onPress: () async {
                    await ref
                        .read(prayerCompletionActionsProvider.notifier)
                        .setPrayerStatus(
                          prayer: prayer,
                          completionDay: completionDay,
                          status: e,
                        );
                  },
                ),
              )
              .toList(),
        ),
      ],
      builder: (context, controller, _) {
        final logged = status;
        final isSet = logged != null && logged != CompletionStatus.none;
        return MouseClick(
          semanticsLabel: menuTriggerLabel,
          onClick: controller.toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSet ? theme.colors.secondary : theme.colors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSet ? theme.colors.secondary : theme.colors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSet) ...[
                  Icon(
                    logged.getIcon(),
                    color: theme.colors.secondaryForeground,
                    size: theme.typography.body.md.fontSize,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      logged.getLocaleName(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.body.sm.copyWith(
                        color: theme.colors.secondaryForeground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    FLucideIcons.chevronDown,
                    color: theme.colors.secondaryForeground,
                    size: theme.typography.body.sm.fontSize,
                  ),
                ] else ...[
                  Text(
                    l10n.logPrayerStatus,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.body.sm.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
