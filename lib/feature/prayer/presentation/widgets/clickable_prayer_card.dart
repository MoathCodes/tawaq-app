import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/core/widgets/mouse_click.dart';
import 'package:hasanat/core/widgets/responsive_widget.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_images.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_tracker_card_model.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: widget.expanded ? 220.h : 110.h,
        ),
        child: MouseClick(
          disabled: _isDisabled,
          onClick: () {
            _handleClick(theme);
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
              curve: Curves.easeInOut,
              child: AnimatedContainer(
                  duration: _animationDuration,
                  curve: Curves.easeInOut,
                  width: widget.expanded ? 250.w : 132.w,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.card,
                    border: Border.all(
                      color: colorScheme.secondaryForeground.withAlpha(45),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(theme.radiusXl),
                    boxShadow: _isHover
                        ? [
                            BoxShadow(
                              color:
                                  colorScheme.secondaryForeground.withAlpha(60),
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
                              widget.cardData.completion?.status ?? _isComplete)
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
                      ).bold,
                      Text(widget.cardData.subtitle,
                              style: TextStyle(
                                  fontSize: widget.expanded ? 16.sp : 10.sp))
                          .muted(),
                    ],
                  )),
            ),
          ),
        ));
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

  Widget _buildStatusChip(CompletionStatus status) {
    return switch (status) {
      CompletionStatus.jamaah => SecondaryBadge(
          // enabled: !_isDisabled,
          leading: const Icon(BootstrapIcons.people, color: Colors.green),
          // onPressed: _handleClick,
          child: Text(_isComplete.getLocaleName(context.l10n)),
        ),
      CompletionStatus.onTime => SecondaryBadge(
          // enabled: !_isDisabled,
          leading: const Icon(BootstrapIcons.checkCircle, color: Colors.yellow),
          // onPressed: _handleClick,
          child: Text(
            _isComplete.getLocaleName(context.l10n),
          )),
      CompletionStatus.late => SecondaryBadge(
          // enabled: !_isDisabled,
          leading: const Icon(BootstrapIcons.clock, color: Colors.orange),
          // onPressed: _handleClick,
          child: Text(_isComplete.getLocaleName(context.l10n)),
        ),
      CompletionStatus.missed => SecondaryBadge(
          // enabled: !_isDisabled,
          leading: const Icon(BootstrapIcons.xCircle, color: Colors.red),
          // onPressed: _handleClick,
          child: Text(_isComplete.getLocaleName(context.l10n)),
        ),
      CompletionStatus.none => const SizedBox.shrink(),
    };
  }

  void _handleClick(ThemeData theme) {
    final completer = ResponsiveContainer.isMobile(context)
        ? _showCompletionDialog(context)
        : _showCompletionPopover(context, theme);
    completer.future.then(
      (value) {
        if (value == null) return;
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
      },
    );
  }

  OverlayCompleter<CompletionStatus?> _showCompletionDialog(
      BuildContext context) {
    return showDropdown(
      context: context,
      builder: (context) => DropdownMenu(children: [
        MenuLabel(child: Text(context.l10n.completionStatus)),
        const MenuDivider(),
        MenuButton(
            onPressed: (context) {
              closeOverlay(context, CompletionStatus.jamaah);
            },
            leading: const Icon(BootstrapIcons.people, color: Colors.green),
            child: Text(context.l10n.jamaah)),
        MenuButton(
            onPressed: (context) {
              closeOverlay(context, CompletionStatus.onTime);
            },
            leading:
                const Icon(BootstrapIcons.checkCircle, color: Colors.yellow),
            child: Text(context.l10n.onTime)),
        MenuButton(
            onPressed: (context) {
              closeOverlay(context, CompletionStatus.late);
            },
            leading: const Icon(BootstrapIcons.clock, color: Colors.orange),
            child: Text(context.l10n.late)),
        MenuButton(
            onPressed: (context) {
              closeOverlay(context, CompletionStatus.missed);
            },
            leading: const Icon(BootstrapIcons.xCircle, color: Colors.red),
            child: Text(context.l10n.missed)),
      ]),
    );
  }

  OverlayCompleter<CompletionStatus?> _showCompletionPopover(
      BuildContext context, ThemeData theme) {
    return showPopover(
      context: context,
      alignment: Alignment.topCenter,
      offset: const Offset(0, 2),
      overlayBarrier: OverlayBarrier(
        borderRadius: theme.borderRadiusLg,
      ),
      builder: (context) {
        return ModalContainer(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            width: 200,
            child: Column(
              spacing: 8,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.completionStatus,
                  textAlign: TextAlign.center,
                ).bold(),
                const Divider(
                  height: 16,
                ),
                Button(
                  style: const ButtonStyle.menubar(density: ButtonDensity.icon),
                  leading:
                      const Icon(BootstrapIcons.people, color: Colors.green),
                  child: Text(context.l10n.jamaah),
                  onPressed: () {
                    closeOverlay(context, CompletionStatus.jamaah);
                  },
                ),
                Button(
                  style: const ButtonStyle.menubar(density: ButtonDensity.icon),
                  leading: const Icon(BootstrapIcons.checkCircle,
                      color: Colors.yellow),
                  child: Text(context.l10n.onTime),
                  onPressed: () {
                    closeOverlay(context, CompletionStatus.onTime);
                  },
                ),
                Button(
                  style: const ButtonStyle.menubar(density: ButtonDensity.icon),
                  leading:
                      const Icon(BootstrapIcons.clock, color: Colors.orange),
                  child: Text(context.l10n.late),
                  onPressed: () {
                    closeOverlay(context, CompletionStatus.late);
                  },
                ),
                Button(
                  style: const ButtonStyle.menubar(density: ButtonDensity.icon),
                  leading:
                      const Icon(BootstrapIcons.xCircle, color: Colors.red),
                  child: Text(context.l10n.missed),
                  onPressed: () {
                    closeOverlay(context, CompletionStatus.missed);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
