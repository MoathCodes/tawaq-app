import 'package:adhan_dart/src/Prayer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/core/widgets/custom_text_button.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_card_model.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_images.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_card/prayer_card_provider.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/mini_card.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class CurrentPrayerCard extends ConsumerWidget {
  const CurrentPrayerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardStream = ref.watch(prayerCardProvider);
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 330),
      decoration: BoxDecoration(
        image: cardStream.map(
            data: (data) => _decorationImage(data.value.prayer),
            error: (error) => _decorationImage(Prayer.fajrAfter),
            loading: (loading) => _decorationImage(Prayer.fajr)),
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(theme.radiusXl),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(theme.radiusXl),
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
          data: (data) => _MainWidget(value: data),
          error: (error, stackTrace) => Text("Error $error"),
          loading: () =>
              _MainWidget(value: PrayerCardInfo.empty()).asSkeleton(),
        ),
      ),
    );
  }

  DecorationImage _decorationImage(Prayer prayer) {
    return DecorationImage(
      image: AssetImage(prayer.imagePath),
      fit: BoxFit.cover,
      alignment: prayer.alignment,
    );
  }
}

class _MainWidget extends StatelessWidget {
  final PrayerCardInfo value;

  const _MainWidget({
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final shadowedText = TextStyle(
      color: Colors.white,
      fontSize: 36.sp,
      fontWeight: FontWeight.bold,
      shadows: [
        const Shadow(
          offset: Offset(1, 1),
          blurRadius: 2,
          color: Color.from(alpha: 0.6, red: 0, green: 0, blue: 0),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.l10n.nextPrayer,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ).small.muted,
        Text(
          value.prayer.getLocaleName(context.l10n),
          style: shadowedText,
        ),
        Text(
          value.time,
          style: shadowedText.copyWith(
            fontSize: 32.sp,
            color: Colors.white,
          ),
        ),
        Text(
          context.l10n.prepareForPrayer,
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
        ).small,
        Wrap(
          alignment: WrapAlignment.spaceEvenly,
          children: [
            MiniCard(
              label: context.l10n.adhan,
              child: Text(
                value.adhanTime,
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
            MiniCard(
              label: context.l10n.iqamah,
              child: Text(
                value.iqamahTime,
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
            MiniCard(
              label: "Make Done",
              child: CustomTextButton(
                onPressed: () {},
                label: "Here",
              ),
            ),
          ],
        ),
      ],
    );
  }
}
