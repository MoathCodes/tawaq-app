import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/theme/theme.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';
import 'package:hasanat/core/widgets/f_skeletonizer.dart';
import 'package:hasanat/core/widgets/icon_badge.dart';
import 'package:hasanat/core/widgets/mouse_click.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_card_model.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_images.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_card/prayer_card_provider.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/mini_card.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';

class CurrentPrayerCard extends ConsumerWidget {
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

  static const _borderRadius = BorderRadius.all(Radius.circular(15));

  static const _containerPadding = EdgeInsets.all(16);
  static const _animationDuration = Duration(milliseconds: 330);
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
    final completion = ref.watch(
      prayerCompletionProvider.select(
        (value) => value[cardStream.value?.prayer],
      ),
    );
    final appTheme = ref.watch(themeProvider);
    final theme = FTheme.of(context);

    return HoverCard(
      backgroundColor: Colors.transparent,
      borderColor: Colors.transparent,
      padding: EdgeInsets.zero,
      child: cardStream.when(
        data: (data) => _PrayerCardContent(
          data: data,
          completion: completion,
          appTheme: appTheme,
          theme: theme,
        ),
        error: (error, stackTrace) => _ErrorCard(error: error),
        loading: () => FSkeletonizer(
          child: _PrayerCardContent(
            data: _MockPrayerData(),
            completion: null,
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

// Extract completion badge to its own widget
class _CompletionBadge extends ConsumerWidget {
  const _CompletionBadge({
    required this.completion,
    required this.appTheme,
    required this.data,
  });
  final PrayerCompletion completion;

  final AsyncValue<ThemeSettings?> appTheme;
  final PrayerCardInfo data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FPopoverMenu(
      menu: [
        FItemGroup(
          children: CompletionStatus.values
              .where((e) => e != CompletionStatus.none)
              .map(
                (e) => FItem(
                  title: Text(e.getLocaleName(context.l10n)),
                  prefix: Icon(
                    e.getIcon(),
                    color: e.getBadgeColor(
                      isDark: appTheme.value?.themeMode == ThemeMode.dark,
                    ),
                  ),
                  onPress: () => _updateCompletion(e, ref),
                ),
              )
              .toList(),
        ),
      ],
      builder: (context, value, child) => MouseClick(
        onClick: value.toggle,
        child: IconBadge(
          style: (p0) => p0.copyWith(
            decoration: p0.decoration.copyWith(
              color: completion.status.getBadgeColor(
                isDark: appTheme.value?.themeMode == ThemeMode.dark,
              ),
            ),
          ),
          icon: Icon(
            completion.status.getIcon(),
            size: 16,
            color: Colors.white,
          ),
          label: Text(
            completion.status.getLocaleName(context.l10n),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _updateCompletion(CompletionStatus status, WidgetRef ref) {
    ref
        .read(prayerCompletionProvider.notifier)
        .addOrUpdateCompletion(
          PrayerCompletion(
            id: completion.id,
            prayer: data.prayer,
            completionTime: DateTime.now(),
            status: status,
          ),
        );
  }
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
  final PrayerCompletion? completion;

  final AsyncValue<ThemeSettings?> appTheme;
  final PrayerCardInfo data;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.l10n.nextPrayer,
          style: CurrentPrayerCard._headerTextStyle,
        ),
        if (completion != null &&
            completion!.status != CompletionStatus.none &&
            !isLoading)
          _CompletionBadge(
            completion: completion!,
            appTheme: appTheme,
            data: data,
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
    required this.completion,
    required this.appTheme,
    required this.theme,
    this.isLoading = false,
  });
  final PrayerCardInfo data;

  final PrayerCompletion? completion;
  final AsyncValue<ThemeSettings?> appTheme;
  final FThemeData theme;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _HeaderRow(
              completion: completion,
              appTheme: appTheme,
              data: data,
              isLoading: isLoading,
            ),
            const SizedBox(height: 4),
            Text(
              data.prayer.getLocaleName(context.l10n),
              style: CurrentPrayerCard._shadowedTextStyle(42.sp),
            ),
            Text(data.time, style: CurrentPrayerCard._shadowedTextStyle(32.sp)),
            Text(
              context.l10n.prepareForPrayer,
              style: CurrentPrayerCard._prepareTextStyle,
            ),
            const SizedBox(height: 4),
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
