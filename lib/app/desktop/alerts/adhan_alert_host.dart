import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/app/desktop/alerts/adhan_alert_card.dart';
import 'package:tawaq/app/desktop/alerts/prayer_alert_dispatcher.dart';
import 'package:tawaq/core/widgets/animation_entry.dart';
import 'package:tawaq/theme/theme.dart';

/// Root overlay that renders the dismissible adhan alert above app content.
///
/// Uses [OverlayPortal] plus [ref.listen] so alert state changes rebuild only
/// this host, not the router subtree wrapped by [child].
class AdhanAlertHost extends ConsumerStatefulWidget {
  /// Creates [AdhanAlertHost].
  const AdhanAlertHost({required this.child, super.key});

  /// Wrapped app subtree.
  final Widget child;

  @override
  ConsumerState<AdhanAlertHost> createState() => _AdhanAlertHostState();
}

class _AdhanAlertHostState extends ConsumerState<AdhanAlertHost> {
  final _portalController = OverlayPortalController();
  var _showing = false;
  var _compact = false;

  void _syncAlertState(PrayerAlertSession? alert) {
    final showing = alert != null;
    final compact = alert?.isCompactMorph ?? false;
    if (showing == _showing && compact == _compact) return;

    setState(() {
      _showing = showing;
      _compact = compact;
    });

    if (showing && !_portalController.isShowing) {
      _portalController.show();
    } else if (!showing && _portalController.isShowing) {
      _portalController.hide();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncAlertState(ref.read(prayerAlertSessionStateProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      prayerAlertSessionStateProvider,
      (_, next) => _syncAlertState(next),
    );

    final wrappedChild = _compact
        ? Offstage(child: widget.child)
        : IgnorePointer(ignoring: _showing, child: widget.child);

    return OverlayPortal(
      controller: _portalController,
      overlayChildBuilder: (context) => const _AdhanAlertOverlay(),
      child: wrappedChild,
    );
  }
}

class _AdhanAlertOverlay extends ConsumerWidget {
  const _AdhanAlertOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alert = ref.watch(prayerAlertSessionStateProvider);
    if (alert == null) return const SizedBox.shrink();

    final compact = alert.isCompactMorph;
    final colors = context.theme.colors;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (!compact)
          Positioned.fill(
            child: ModalBarrier(
              color: colors.barrier.withValues(alpha: 0.45),
              dismissible: false,
            ),
          ),
        Positioned.fill(
          child: FocusScope(
            autofocus: true,
            child: compact
                ? ColoredBox(
                    color: colors.card,
                    child: const Align(
                      alignment: Alignment.topCenter,
                      child: AdhanAlertCard(),
                    ),
                  )
                : Center(
                    child: AnimationEntry(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: kAdhanAlertCompactSize.width,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: AdhanAlertCard(showCloseButton: true),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
