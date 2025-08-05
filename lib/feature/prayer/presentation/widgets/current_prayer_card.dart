import 'package:adhan_dart/src/Prayer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/core/widgets/hover_card.dart';
import 'package:hasanat/core/widgets/icon_badge.dart';
import 'package:hasanat/core/widgets/mouse_click.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_images.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_card/prayer_card_provider.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/mini_card.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';

class CurrentPrayerCard extends ConsumerWidget {
  const CurrentPrayerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardStream = ref.watch(prayerCardProvider);
    final completion =
        ref.watch(prayerCompletionNotifierProvider)[cardStream.value?.prayer];
    final appTheme = ref.watch(themeNotifierProvider);
    final theme = FTheme.of(context);
    final shadowedText = TextStyle(
      color: Colors.white,
      fontSize: 42.sp,
      fontWeight: FontWeight.bold,
      shadows: [
        const Shadow(
          offset: Offset(1, 1),
          blurRadius: 2,
          color: Color.from(alpha: 0.6, red: 0, green: 0, blue: 0),
        ),
      ],
    );

    return HoverCard(
      backgroundColor: Colors.transparent,
      borderColor: Colors.transparent,
      padding: const EdgeInsets.all(0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 330),
        decoration: BoxDecoration(
          image: cardStream.map(
              data: (data) => _decorationImage(data.value.prayer),
              error: (error) => _decorationImage(Prayer.fajrAfter),
              loading: (loading) => _decorationImage(Prayer.fajr)),
          color: theme.colors.secondary,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.from(alpha: 0.2, red: 0, green: 0, blue: 0),
                Color.from(alpha: 0.3, red: 0, green: 0, blue: 0),
              ],
            ),
          ),
          child: cardStream.when(
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 4,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.nextPrayer,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (completion != null &&
                        completion.status != CompletionStatus.none)
                      FPopoverMenu(
                        menu: [
                          FItemGroup(
                            children: CompletionStatus.values
                                .where((e) => e != CompletionStatus.none)
                                .map((e) => FItem(
                                      title:
                                          Text(e.getLocaleName(context.l10n)),
                                      prefix: Icon(e.getIcon(),
                                          color: e.getBadgeColor(
                                              isDark:
                                                  appTheme.value?.themeMode ==
                                                      ThemeMode.dark)),
                                      onPress: () {
                                        ref
                                            .read(
                                                prayerCompletionNotifierProvider
                                                    .notifier)
                                            .addOrUpdateCompletion(
                                              PrayerCompletion(
                                                id: completion.id,
                                                prayer: data.prayer,
                                                completionTime: DateTime.now(),
                                                status: e,
                                              ),
                                            );
                                      },
                                    ))
                                .toList(),
                          ),
                        ],
                        builder: (context, value, child) => MouseClick(
                          onClick: value.toggle,
                          child: IconBadge(
                            style: (p0) => p0.copyWith(
                              decoration: p0.decoration.copyWith(
                                color: completion.status.getBadgeColor(
                                  isDark: appTheme.value?.themeMode ==
                                      ThemeMode.dark,
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
                      ),
                  ],
                ),
                Text(
                  data.prayer.getLocaleName(context.l10n),
                  style: shadowedText,
                ),
                Text(
                  data.time,
                  style: shadowedText.copyWith(
                    fontSize: 32.sp,
                    color: Colors.white,
                  ),
                ),
                Text(
                  context.l10n.prepareForPrayer,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                ),
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
            error: (error, stackTrace) => Text("Error $error"),
            loading: () => const Text("Loading"),
          ),
        ),
      ),
    );
  }

  DecorationImage _decorationImage(Prayer prayer) {
    return DecorationImage(
      image: AssetImage(prayer.imagePath),
      alignment: prayer.alignment,
      fit: BoxFit.cover,
      // colorFilter: const ColorFilter.mode(
      //   Colors.black12,
      //   BlendMode.darken,
      // ),
    );
  }
}
