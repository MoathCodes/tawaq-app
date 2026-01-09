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
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_card_model.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_images.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_card/prayer_card_provider.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/mini_card.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/theme/theme.dart';

/// Widget that displays the current prayer information in a card.
class CurrentPrayerCard extends ConsumerWidget {
  /// Creates a [CurrentPrayerCard] instance.
  const CurrentPrayerCard({super.key});
  // Static constants to avoid recreation on every build
  static const _gradientOverlay = LinearGradient(
    colors: [
      Color.from(alpha: 0.6, red: 0, green: 0, blue: 0), // Strongest at top
      Color.from(alpha: 0.4, red: 0, green: 0, blue: 0), // Medium in middle
      Color.from(alpha: 0.1, red: 0, green: 0, blue: 0), // Weakest at bottom
    ],
    stops: [0.0, 0.5, 1.0], // Control the gradient distribution
  );
  // Static constants for the gradient above but for RTL
  static const _gradientOverlayRLT = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [
      Color.from(alpha: 0.6, red: 0, green: 0, blue: 0), // Strongest at top
      Color.from(alpha: 0.4, red: 0, green: 0, blue: 0), // Medium in middle
      Color.from(alpha: 0.1, red: 0, green: 0, blue: 0), // Weakest at bottom
    ],
    stops: [0.0, 0.5, 1.0], // Control the gradient distribution
  );
  static const _textShadow = [
    Shadow(
      offset: Offset(1, 1),
      blurRadius: 2,
      color: Color.from(alpha: 0.6, red: 0, green: 0, blue: 0),
    ),
  ];

  /// Use context.theme.radii.lg instead - kept for backward compat
  static const _borderRadius = BorderRadius.all(Radius.circular(12));

  /// Use context.edgeInsets(all: AppSpacing.lg) instead - kept for backward compat
  static const EdgeInsets _containerPadding = .all(AppSpacing.lg);

  /// Use context.theme.durations.normal instead - kept for backward compat
  static const _animationDuration = Duration(milliseconds: 260);
  static TextStyle get _headerTextStyle => TextStyle(
    color: Colors.white,
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
  );
  static TextStyle get _miniCardTextStyle => TextStyle(fontSize: 20.sp);

  static TextStyle get _prepareTextStyle =>
      TextStyle(color: Colors.white, fontSize: 16.sp);

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
        data: (data) =>
            _PrayerCardContent(data: data, appTheme: appTheme, theme: theme),
        error: (error, stackTrace) => _ErrorCard(error: error),
        loading: () => FSkeletonizer(
          child: _PrayerCardContent(
            data: _MockPrayerData(),
            appTheme: appTheme,
            theme: theme,
            isLoading: true,
          ),
        ),
      ),
    );
  }

  // Cached style getters
  static TextStyle _shadowedTextStyle(double fontSize) => TextStyle(
    color: Colors.white,
    fontSize: fontSize,
    fontWeight: FontWeight.bold,
    shadows: _textShadow,
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return FAlert(
      title: Text(context.l10n.errorOccurredWhile('Calculating Prayer Times')),
      subtitle: Text(error.toString()),
    );
  }
}

// Optimized header row
class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.completion,
    required this.appTheme,
    required this.data,
    required this.isLoading,
  });
  final Future<PrayerCompletion?> completion;
  final AsyncValue<ThemeSettings?> appTheme;

  final PrayerCardInfo data;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        Text(
          context.l10n.nextPrayer,
          style: CurrentPrayerCard._headerTextStyle,
        ),
      ],
    );
  }
}

// Mock data for loading state
class _MockPrayerData implements PrayerCardInfo {
  @override
  String get adhanTime => '--:--';
  @override
  $PrayerCardInfoCopyWith<PrayerCardInfo> get copyWith =>
      throw UnimplementedError();
  @override
  String get iqamahTime => '--:--';
  @override
  Prayer get prayer => Prayer.fajr;

  @override
  String get time => 'Loading...';
}

// Separate widget for the main content to optimize rebuilds
class _PrayerCardContent extends ConsumerWidget {
  const _PrayerCardContent({
    required this.data,
    required this.appTheme,
    required this.theme,
    this.isLoading = false,
  });
  final PrayerCardInfo data;

  final AsyncValue<ThemeSettings?> appTheme;
  final FThemeData theme;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completion = ref
        .read(prayerCompletionProvider.notifier)
        .getPrayerCompletionForPrayerOnDate(
          data.prayer,
          ref.read(currentLocationTimeProvider),
        );
    final isArabic =
        ref.watch(
          localeProvider.select((value) => value.value?.languageCode),
        ) ==
        'ar';
    return AnimatedContainer(
      duration: CurrentPrayerCard._animationDuration,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(data.prayer.imagePath),

          alignment: data.prayer.alignment,
          fit: BoxFit.fitWidth,
          // filterQuality: FilterQuality.medium,
        ),
        color: theme.colors.secondary,
        borderRadius: CurrentPrayerCard._borderRadius,
      ),
      child: Container(
        padding: CurrentPrayerCard._containerPadding,
        decoration: BoxDecoration(
          borderRadius: CurrentPrayerCard._borderRadius,
          gradient: isArabic
              ? CurrentPrayerCard._gradientOverlayRLT
              : CurrentPrayerCard._gradientOverlay,
        ),
        child: Column(
          crossAxisAlignment: .stretch,
          mainAxisAlignment: .spaceBetween,
          children: [
            _HeaderRow(
              completion: completion,
              appTheme: appTheme,
              data: data,
              isLoading: isLoading,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              data.prayer.getLocaleName(context.l10n),
              style: CurrentPrayerCard._shadowedTextStyle(42.sp),
            ),
            Text(data.time, style: CurrentPrayerCard._shadowedTextStyle(32.sp)),
            Text(
              context.l10n.prepareForPrayer,
              style: CurrentPrayerCard._prepareTextStyle,
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              children: [
                MiniCard(
                  label: context.l10n.adhan,
                  child: Text(
                    data.adhanTime,
                    style: CurrentPrayerCard._miniCardTextStyle,
                  ),
                ),
                MiniCard(
                  label: context.l10n.iqamah,
                  child: Text(
                    data.iqamahTime,
                    style: CurrentPrayerCard._miniCardTextStyle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Note: DecorationImage provider is now sized via ResizeImage in build.
}
