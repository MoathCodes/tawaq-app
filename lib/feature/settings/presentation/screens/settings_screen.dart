import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/centered_viewport_shell.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_platform.dart';
import 'package:tawaq/core/widgets/icon_label.dart';
import 'package:tawaq/feature/settings/presentation/models/settings_destination.dart';
import 'package:tawaq/feature/settings/presentation/provider/ui_state_settings_providers.dart';

/// Screen for application settings.
class SettingsScreen extends HookConsumerWidget {
  /// Creates a new [SettingsScreen] instance.
  const SettingsScreen({this.section, super.key});

  /// Optional tab to open; null restores the persisted tab.
  final SettingsDestination? section;

  static const _maxContentWidth = 800.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final showKeyboardShortcuts = supportsKeyboardShortcuts;
    final persistedKey = ref.watch(
      settingsScreenSettingsProvider.select((s) => s.value?.activeTabKey),
    );

    final destinations = useMemoized(
      () => visibleDestinations(showKeyboardShortcuts: showKeyboardShortcuts),
      [showKeyboardShortcuts],
    );

    final resolvedDestination = useMemoized(
      () => resolveVisibleDestination(
        section ?? destinationForKey(persistedKey),
        showKeyboardShortcuts: showKeyboardShortcuts,
      ),
      [section, persistedKey, showKeyboardShortcuts],
    );

    final initialIndex = indexForDestination(
      resolvedDestination,
      showKeyboardShortcuts: showKeyboardShortcuts,
    ).clamp(0, destinations.length - 1);

    final tabController = useTabController(
      initialLength: destinations.length,
      initialIndex: initialIndex,
    );
    final tabsStyle = context.theme.tabsStyle;

    useEffect(
      () {
        if (section == null) {
          return null;
        }

        final index = indexForDestination(
          section!,
          showKeyboardShortcuts: showKeyboardShortcuts,
        );
        if (index < 0) {
          return null;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!tabController.indexIsChanging && tabController.index != index) {
            tabController.animateTo(index);
          }
          ref
              .read(settingsScreenSettingsProvider.notifier)
              .setActiveDestination(section!);
        });

        return null;
      },
      [section, showKeyboardShortcuts],
    );

    useEffect(
      () {
        void onTabChanged() {
          if (tabController.indexIsChanging) {
            return;
          }
          final destination = destinations[tabController.index];
          ref
              .read(settingsScreenSettingsProvider.notifier)
              .setActiveDestination(destination);
        }

        tabController.addListener(onTabChanged);
        return () => tabController.removeListener(onTabChanged);
      },
      [tabController, destinations],
    );

    return CenteredViewportShell(
      maxContentWidth: _maxContentWidth,
      header: DecoratedBox(
        decoration: tabsStyle.decoration,
        child: TabBar(
          controller: tabController,
          tabs: [
            for (final destination in destinations)
              Tab(
                height: tabsStyle.height,
                child: IconLabel(
                  label: destination.label(l10n),
                  icon: destination.icon,
                  excludeIconSemantics: true,
                ),
              ),
          ],
          padding: tabsStyle.padding,
          indicator: tabsStyle.indicatorDecoration,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: tabsStyle.labelTextStyle.resolve({
            context.platformVariant,
            FTabVariant.selected,
          }),
          unselectedLabelStyle: tabsStyle.labelTextStyle.resolve({
            context.platformVariant,
          }),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: tabsStyle.spacing),
          Expanded(
            child: TabBarView(
              controller: tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                for (final (i, destination) in destinations.indexed)
                  centeredViewportScrollTab(
                    maxContentWidth: _maxContentWidth,
                    child: KeyedSubtree(
                      key: ValueKey(
                        'settings-tab-${destination.labelKey}-$i',
                      ),
                      child: settingsDestinationBody(destination, l10n)
                          .animate()
                          .fadeIn(duration: 200.ms, curve: Curves.easeOut)
                          .moveY(
                            begin: 12,
                            end: 0,
                            duration: 280.ms,
                            curve: Curves.easeOutCubic,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
