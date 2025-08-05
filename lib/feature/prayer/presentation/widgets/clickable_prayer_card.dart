import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/core/utils/text_extensions.dart';
import 'package:hasanat/core/widgets/icon_badge.dart';
import 'package:hasanat/core/widgets/mouse_click.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_images.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_tracker_card_model.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';

class ClickablePrayerCard extends ConsumerStatefulWidget {
  final PrayerTrackerCardModel cardData;
  final DateTime completionTime;
  final void Function(PrayerCompletion prayerCompletion)? onCompletionChanged;
  final bool expanded;
  const ClickablePrayerCard({
    required this.cardData,
    required this.completionTime,
    this.expanded = true,
    this.onCompletionChanged,
    super.key,
  });

  @override
  ConsumerState<ClickablePrayerCard> createState() =>
      _ClickablePrayerCardState();
}

class _ClickablePrayerCardState extends ConsumerState<ClickablePrayerCard> {
  static const Duration _animationDuration = Duration(milliseconds: 200);

  bool _isHover = false;

  bool _isDisabled = false;

  late CompletionStatus _isComplete;
  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final colorScheme = theme.colors;
    return FPopoverMenu(
      menu: [
        FItemGroup(children: [
          FItem(
            prefix: Icon(CompletionStatus.jamaah.getIcon(),
                color: CompletionStatus.jamaah.getBadgeColor()),
            title: Text(context.l10n.jamaah),
            onPress: () {
              _handleClick(CompletionStatus.jamaah);
            },
          ),
          FItem(
            // style: const ButtonStyle.menubar(density: ButtonDensity.icon),
            prefix: Icon(CompletionStatus.onTime.getIcon(),
                color: CompletionStatus.onTime.getBadgeColor()),
            title: Text(context.l10n.onTime),
            onPress: () {
              _handleClick(CompletionStatus.onTime);
            },
          ),
          FItem(
            // style: const ButtonStyle.menubar(density: ButtonDensity.icon),
            prefix: Icon(CompletionStatus.late.getIcon(),
                color: CompletionStatus.late.getBadgeColor()),
            title: Text(context.l10n.late),
            onPress: () {
              _handleClick(CompletionStatus.late);
            },
          ),
          FItem(
            // style: const ButtonStyle.menubar(density: ButtonDensity.icon),
            prefix: Icon(CompletionStatus.missed.getIcon(),
                color: CompletionStatus.missed.getBadgeColor()),
            title: Text(context.l10n.missed),
            onPress: () {
              _handleClick(CompletionStatus.missed);
            },
          ),
        ])
      ],
      builder: (context, controller, child) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: widget.expanded ? 200.h : 110.h,
          ),
          child: MouseClick(
            disabled: _isDisabled,
            onClick: () {
              controller.toggle();
            },
            onExit: (event) {
              setState(() {
                _isHover = false;
              });
            },
            onHover: (event) {
              setState(() {
                _isHover = true;
              });
            },
            child: AnimatedOpacity(
              duration: _animationDuration,
              opacity: _isDisabled ? 0.5 : 1.0,
              curve: Curves.easeInOut,
              onEnd: () {
                if (widget.cardData.isTimePassed) {
                  setState(() {
                    _isHover = false;
                  });
                }
              },
              child: AnimatedScale(
                duration: _animationDuration,
                scale: _isHover ? 1.05 : 1.0,
                curve: Curves.bounceInOut,
                child: AnimatedContainer(
                    duration: _animationDuration,
                    curve: Curves.easeInOut,
                    width: widget.expanded ? 250.w : 132.w,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.cardStyle.decoration.color,
                      border: Border.all(
                        color: colorScheme.secondary.withAlpha(45),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isHover
                          ? [
                              BoxShadow(
                                color: colorScheme.secondaryForeground
                                    .withAlpha(60),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: widget.expanded ? 46.w : 30.w,
                              height: widget.expanded ? 46.h : 30.h,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(
                                      widget.cardData.prayer.imagePath),
                                  fit: BoxFit.cover,
                                  alignment: widget.cardData.prayer.alignment,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            _buildStatusChip(
                                widget.cardData.completion?.status ??
                                    _isComplete,
                                theme,
                                ref
                                        .watch(themeNotifierProvider)
                                        .value
                                        ?.themeMode ==
                                    ThemeMode.dark),
                          ],
                        ),
                        Text(widget.cardData.prayer.getLocaleName(context.l10n),
                                style: TextStyle(
                                    fontSize: widget.expanded ? 26.sp : 13.sp))
                            .bold,
                        Text(
                          widget.cardData.adhan,
                          style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: widget.expanded ? 26.sp : 13.sp),
                        ),
                        Text(widget.cardData.subtitle,
                            style: TextStyle(
                                fontSize: widget.expanded ? 16.sp : 10.sp)),
                      ],
                    )),
              ),
            ),
          )),
    );
  }

  @override
  void didUpdateWidget(covariant ClickablePrayerCard oldWidget) {
    if (oldWidget.cardData != widget.cardData) {
      setState(() {
        _isDisabled = !widget.cardData.isTimePassed;
        _isComplete =
            widget.cardData.completion?.status ?? CompletionStatus.none;
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    super.initState();
    _isDisabled = !widget.cardData.isTimePassed;
    _isComplete = widget.cardData.completion?.status ?? CompletionStatus.none;
  }

  Widget _buildStatusChip(
      CompletionStatus status, FThemeData theme, bool isDarkMode) {
    final style = theme.typography.sm.copyWith(color: Colors.white);
    return switch (status) {
      CompletionStatus.jamaah => IconBadge(
          style: (p0) => p0.copyWith(
            decoration: p0.decoration.copyWith(
              color: isDarkMode ? Colors.green.shade900 : Colors.green.shade600,
            ),
          ),
          icon: const Icon(FIcons.users, size: 16, color: Colors.white),
          label: Text(
            _isComplete.getLocaleName(context.l10n),
            style: style,
          ),
        ),
      CompletionStatus.onTime => IconBadge(
          style: (p0) => p0.copyWith(
            decoration: p0.decoration.copyWith(
              color:
                  isDarkMode ? Colors.yellow.shade900 : Colors.yellow.shade600,
            ),
          ),
          icon: const Icon(FIcons.checkCheck, size: 16, color: Colors.white),
          label: Text(
            _isComplete.getLocaleName(context.l10n),
            style: style,
          ),
        ),
      CompletionStatus.late => IconBadge(
          style: (p0) => p0.copyWith(
            decoration: p0.decoration.copyWith(
              color:
                  isDarkMode ? Colors.orange.shade900 : Colors.orange.shade600,
            ),
          ),
          icon: const Icon(FIcons.clock, size: 16, color: Colors.white),
          label: Text(
            _isComplete.getLocaleName(context.l10n),
            style: style,
          ),
        ),
      CompletionStatus.missed => IconBadge(
          style: (p0) => p0.copyWith(
            decoration: p0.decoration.copyWith(
              color: isDarkMode ? Colors.red.shade900 : Colors.red.shade600,
            ),
          ),
          icon: const Icon(FIcons.circleX, size: 16, color: Colors.white),
          label: Text(
            _isComplete.getLocaleName(context.l10n),
            style: style,
          ),
        ),
      CompletionStatus.none => const SizedBox.shrink(),
    };
  }

  void _handleClick(CompletionStatus value) {
    if (mounted) {
      setState(() {
        _isComplete = value;
      });
    }
    widget.onCompletionChanged?.call(
      PrayerCompletion(
        id: widget.cardData.completion?.id,
        status: value,
        prayer: widget.cardData.prayer,
        completionTime: widget.completionTime,
      ),
    );
    // controller.hide();
  }
}
