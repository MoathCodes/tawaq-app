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
import 'package:tawaq/feature/settings/presentation/provider/ui_state_settings_providers.dart';
import 'package:tawaq/theme/spacing.dart';

/// Screen for application settings.
class SettingsScreen extends HookConsumerWidget {
  /// Creates a new [SettingsScreen] instance.
  const SettingsScreen({this.tabKey, super.key});

  /// Optional tab to open; null restores the persisted tab.
  final String? tabKey;

  static const _maxContentWidth = 800.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final showKeyboardShortcuts = supportsKeyboardShortcuts;
    final persistedKey = ref.watch(
      settingsScreenSettingsProvider.select((s) => s.value?.activeTabKey),
    );

    final tabs = useMemoized(
      () => visibleTabs(showKeyboardShortcuts: showKeyboardShortcuts),
      [showKeyboardShortcuts],
    );

    final activeKey = useMemoized(
      () => resolveVisibleTabKey(
        tabKey ?? persistedKey ?? kSettingsDefaultTabKey,
        showKeyboardShortcuts: showKeyboardShortcuts,
      ),
      [tabKey, persistedKey, showKeyboardShortcuts],
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
        if (tabKey == null) {
          return null;
        }

        final index = indexForTabKey(
          tabKey!,
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
              .setActiveTabKey(tabKey!);
        });

        return null;
      },
      [tabKey, showKeyboardShortcuts],
    );

    useEffect(
      () {
        void onTabChanged() {
          if (tabController.indexIsChanging) {
            return;
          }
          ref
              .read(settingsScreenSettingsProvider.notifier)
              .setActiveTabKey(tabs[tabController.index].key);
        }

        tabController.addListener(onTabChanged);
        return () => tabController.removeListener(onTabChanged);
      },
      [tabController, tabs],
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
                      height: tabsStyle.height,
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
                    centeredViewportScrollTab(
                      maxContentWidth: _maxContentWidth,
                      child: LazyTabContent(
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
