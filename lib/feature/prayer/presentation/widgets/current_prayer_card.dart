import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/theme/theme.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';
import 'package:hasanat/core/widgets/f_skeletonizer.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_card_model.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_images.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_card/prayer_card_provider.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/mini_card.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/theme/theme.dart';

/// Widget that displays the current prayer information in a card.
class CurrentPrayerCard extends ConsumerWidget {
  /// Creates a [CurrentPrayerCard] instance.
  const CurrentPrayerCard({super.key});

  static const _gradient = LinearGradient(
    colors: [
      Color.fromRGBO(0, 0, 0, 0.6),
      Color.fromRGBO(0, 0, 0, 0.4),
      Color.fromRGBO(0, 0, 0, 0.1),
    ],
    stops: [0.0, 0.5, 1.0],
  );
  static const _gradientRTL = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [
      Color.fromRGBO(0, 0, 0, 0.6),
      Color.fromRGBO(0, 0, 0, 0.4),
      Color.fromRGBO(0, 0, 0, 0.1),
    ],
    stops: [0.0, 0.5, 1.0],
  );
  static const _shadow = [
    Shadow(
      offset: Offset(1, 1),
      blurRadius: 2,
      color: Color.fromRGBO(0, 0, 0, 0.6),
    ),
  ];
  static const _borderRadius = BorderRadius.all(Radius.circular(12));
  static const _padding = EdgeInsets.all(AppSpacing.lg);
  static const _animDuration = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardStream = ref.watch(prayerCardProvider);
    final appTheme = ref.watch(themeProvider);
    final theme = FTheme.of(context);

    return HoverCard(
      backgroundColor: Colors.transparent,
      borderColor: Colors.transparent,
      padding: .zero,
      child: cardStream.when(
        data: (data) => _Content(data: data, appTheme: appTheme, theme: theme),
        error: (e, _) => FAlert(
          title: Text(
            context.l10n.errorOccurredWhile('Calculating Prayer Times'),
          ),
          subtitle: Text(e.toString()),
        ),
        loading: () => FSkeletonizer(
          child: _Content(data: _MockData(), appTheme: appTheme, theme: theme),
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

class _Content extends ConsumerWidget {
  const _Content({
    required this.data,
    required this.appTheme,
    required this.theme,
  });
  final PrayerCardInfo data;
  final AsyncValue<ThemeSettings?> appTheme;
  final FThemeData theme;

  TextStyle _shadowedStyle(double size) => TextStyle(
    color: Colors.white,
    fontSize: size,
    fontWeight: FontWeight.bold,
    shadows: CurrentPrayerCard._shadow,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic =
        ref.watch(localeProvider.select((v) => v.value?.languageCode)) == 'ar';

    return AnimatedContainer(
      duration: CurrentPrayerCard._animDuration,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(data.prayer.imagePath),
          alignment: data.prayer.alignment,
          fit: BoxFit.fitWidth,
        ),
        color: theme.colors.secondary,
        borderRadius: CurrentPrayerCard._borderRadius,
      ),
      child: Container(
        padding: CurrentPrayerCard._padding,
        decoration: BoxDecoration(
          borderRadius: CurrentPrayerCard._borderRadius,
          gradient: isArabic
              ? CurrentPrayerCard._gradientRTL
              : CurrentPrayerCard._gradient,
        ),
        child: Column(
          crossAxisAlignment: .stretch,
          mainAxisAlignment: .spaceBetween,
          children: [
            Text(
              context.l10n.nextPrayer,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              data.prayer.getLocaleName(context.l10n),
              style: _shadowedStyle(42.sp),
            ),
            Text(data.time, style: _shadowedStyle(32.sp)),
            Text(
              context.l10n.prepareForPrayer,
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              children: [
                MiniCard(
                  label: context.l10n.adhan,
                  child: Text(
                    data.adhanTime,
                    style: TextStyle(fontSize: 20.sp),
                  ),
                ),
                MiniCard(
                  label: context.l10n.iqamah,
                  child: Text(
                    data.iqamahTime,
                    style: TextStyle(fontSize: 20.sp),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
