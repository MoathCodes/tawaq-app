import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/centered_viewport_shell.dart';
import 'package:tawaq/core/layout/lazy_tab_content.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_platform.dart';
import 'package:tawaq/core/widgets/icon_label.dart';
import 'package:tawaq/feature/settings/presentation/models/settings_tabs.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_screen_settings_provider.dart';
import 'package:tawaq/theme/spacing.dart';

/// Screen for application settings.
class SettingsScreen extends HookConsumerWidget {
  /// Creates a new [SettingsScreen] instance.
  const new({this.tabKey, this.onTabChanged, super.key});

  /// Optional tab to open; null restores the persisted tab.
  final String? tabKey;

  /// Publishes the canonical tab wire value to app-level routing.
  final ValueChanged<String>? onTabChanged;

  static const _maxContentWidth = 800.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final showKeyboardShortcuts = supportsKeyboardShortcuts;
    final checkpoint = ref.watch(settingsScreenSettingsProvider);
    final persistedKey = checkpoint.value;

    final tabs = useMemoized(
      () => visibleTabs(showKeyboardShortcuts: showKeyboardShortcuts),
      [showKeyboardShortcuts],
    );

    final activeKey = resolveSettingsRouteTab(
      routeKey: tabKey,
      persistedKey: persistedKey,
      showKeyboardShortcuts: showKeyboardShortcuts,
    );

    final initialIndex = indexForTabKey(
      activeKey,
      showKeyboardShortcuts: showKeyboardShortcuts,
    ).clamp(0, tabs.length - 1);

    final tabController = useTabController(
      initialLength: tabs.length,
      initialIndex: initialIndex,
    );
    final tabsStyle = context.theme.tabsStyle;

    useEffect(
      () {
        if (tabKey == null && !checkpoint.hasValue) {
          return null;
        }

        final canonical = resolveSettingsRouteTab(
          routeKey: tabKey,
          persistedKey: persistedKey,
          showKeyboardShortcuts: showKeyboardShortcuts,
        );
        final index = indexForTabKey(
          canonical,
          showKeyboardShortcuts: showKeyboardShortcuts,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          if (tabKey != canonical) {
            onTabChanged?.call(canonical);
          }
          if (!tabController.indexIsChanging && tabController.index != index) {
            tabController.animateTo(index);
          }
          ref
              .read(settingsScreenSettingsProvider.notifier)
              .setActiveTabKey(canonical);
        });

        return null;
      },
      [
        tabKey,
        persistedKey,
        checkpoint.hasValue,
        showKeyboardShortcuts,
        onTabChanged,
      ],
    );

    useEffect(
      () {
        void handleTabChanged() {
          // TabController.index changes near the midpoint of a swipe. Publish
          // only once the tap animation or drag has actually settled.
          if (!settingsTabIsSettled(
            indexIsChanging: tabController.indexIsChanging,
            offset: tabController.offset,
          )) {
            return;
          }
          final key = tabs[tabController.index].key;
          if (tabKey != key && context.mounted) {
            onTabChanged?.call(key);
          }
          ref
              .read(settingsScreenSettingsProvider.notifier)
              .setActiveTabKey(key);
        }

        tabController.addListener(handleTabChanged);
        return () => tabController.removeListener(handleTabChanged);
      },
      [tabController, tabs, tabKey, onTabChanged],
    );

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: CenteredViewportShell(
        maxContentWidth: _maxContentWidth,
        header: LayoutBuilder(
          builder: (context, constraints) {
            final scrollable = !isContainerAtLeast(
              context,
              constraints,
              FBreakpoint.sm,
            );

            return DecoratedBox(
              decoration: tabsStyle.decoration,
              child: TabBar(
                controller: tabController,
                isScrollable: scrollable,
                tabAlignment: scrollable
                    ? TabAlignment.start
                    : TabAlignment.fill,
                tabs: [
                  for (final tab in tabs)
                    Tab(
                      height: tabsStyle.minHeight,
                      child: IconLabel(
                        label: tab.label(l10n),
                        icon: tab.icon,
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
            );
          },
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
                  for (final (i, tab) in tabs.indexed)
                    CenteredViewportShell.scrollTab(
                      maxContentWidth: _maxContentWidth,
                      child: LazyPanelContent.tab(
                        controller: tabController,
                        index: i,
                        builder: () => KeyedSubtree(
                          key: ValueKey('settings-tab-${tab.key}-$i'),
                          child: tab
                              .builder(l10n)
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
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
