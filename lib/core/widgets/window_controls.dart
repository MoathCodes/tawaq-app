import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/desktop/desktop_window_controller.dart';
import 'package:tawaq/core/desktop/window_state_provider.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/core/widgets/merged_action_semantics.dart';
import 'package:tawaq/core/widgets/shell_a11y.dart';
import 'package:tawaq/theme/button_styles.dart';
import 'package:window_manager/window_manager.dart';

/// Window controls for macOS.
class MacOSWindowControls extends StatelessWidget {
  /// Creates a new instance of [MacOSWindowControls].
  const MacOSWindowControls({
    required this.onClose,
    required this.onMinimize,
    required this.onFullscreen,
    required this.isMaximized,
    super.key,
  });

  /// The callback that is called when the close button is tapped.
  final VoidCallback onClose;

  /// The callback that is called when the minimize button is tapped.
  final VoidCallback onMinimize;

  /// The callback that is called when the fullscreen button is tapped.
  final VoidCallback onFullscreen;

  /// Whether the window is currently maximized.
  final bool isMaximized;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        _MacOSControlButton(
          color: const Color(0xFFFF5F57), // Red
          hoverColor: const Color(0xFFFF4A40),
          icon: Icons.close,
          semanticsLabel: ShellA11y.windowClose(l10n),
          onPressed: onClose,
        ),
        _MacOSControlButton(
          color: const Color(0xFFFFBD2E), // Yellow
          hoverColor: const Color(0xFFFFAA00),
          icon: Icons.minimize,
          semanticsLabel: ShellA11y.windowMinimize(l10n),
          onPressed: onMinimize,
        ),
        _MacOSControlButton(
          color: const Color(0xFF28CA42), // Green
          hoverColor: const Color(0xFF00FF57),
          icon: Icons.fullscreen,
          semanticsLabel: isMaximized
              ? ShellA11y.windowRestore(l10n)
              : ShellA11y.windowMaximize(l10n),
          onPressed: onFullscreen,
        ),
      ],
    );
  }
}

/// Window controls that adapt to the current platform.
class WindowControls extends ConsumerWidget {
  /// Creates a new instance of [WindowControls].
  const WindowControls({super.key, this.forceMacStyle});

  /// Whether to force the macOS style.
  final bool? forceMacStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maximized = ref.watch(windowMaximizedProvider).value ?? false;
    final theme = FTheme.of(context);
    final l10n = context.l10n;
    final isMacStyle = Platform.isMacOS || (forceMacStyle ?? false);
    final reverseOrder = Directionality.of(context) == TextDirection.ltr && !isMacStyle; 

    if (isMacStyle) {
      return MacOSWindowControls(
        onClose: () => _closeWindow(ref),
        onMinimize: () => _minimizeWindow(ref),
        isMaximized: maximized,
        onFullscreen: () => _maximizeWindow(maximized: maximized),
      );
    }
    final children =  [
        MergedActionSemantics(
          label: ShellA11y.windowClose(l10n),
          child: FButton.icon(
            style: closeButtonStyle(
              colors: theme.colors,
              typography: theme.typography,
              style: theme.style,
            ),
            onPress: () => _closeWindow(ref),
            child: const Icon(FLucideIcons.x, size: 14),
          ),
        ),
        MergedActionSemantics(
          label: maximized
              ? ShellA11y.windowRestore(l10n)
              : ShellA11y.windowMaximize(l10n),
          child: FButton.icon(
            style: windowControlButtonStyle(
              colors: theme.colors,
              typography: theme.typography,
              style: theme.style,
            ),
            onPress: () => _maximizeWindow(maximized: maximized),
            child: Icon(
              maximized ? FLucideIcons.maximize2 : FLucideIcons.square,
              size: 14,
            ),
          ),
        ),
        MergedActionSemantics(
          label: ShellA11y.windowMinimize(l10n),
          child: FButton.icon(
            style: windowControlButtonStyle(
              colors: theme.colors,
              typography: theme.typography,
              style: theme.style,
            ),
            onPress: () => _minimizeWindow(ref),
            child: const Icon(FLucideIcons.minus, size: 14),
          ),
        ),
      ];

    return Row(
      spacing: 6,
      children: reverseOrder ? children.reversed.toList() : children,
    );
  }

  Future<void> _closeWindow(WidgetRef ref) async {
    if (isDesktopPlatform) {
      await ref.read(desktopWindowControllerProvider).requestClose();
      return;
    }
    await windowManager.close();
  }

  Future<void> _maximizeWindow({required bool maximized}) async {
    if (maximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  Future<void> _minimizeWindow(WidgetRef ref) async {
    if (isDesktopPlatform) {
      await ref.read(desktopWindowControllerProvider).requestMinimize();
      return;
    }
    await windowManager.minimize();
  }
}

class _MacOSControlButton extends HookWidget {
  const _MacOSControlButton({
    required this.color,
    required this.hoverColor,
    required this.icon,
    required this.semanticsLabel,
    this.onPressed,
  });
  final Color color;
  final Color hoverColor;
  final IconData icon;
  final String semanticsLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final (:isHovered, :setHovered) = useHoverState();

    return MergedActionSemantics(
      label: semanticsLabel,
      child: MouseRegion(
        onEnter: (_) => setHovered(value: true),
        onExit: (_) => setHovered(value: false),
        child: GestureDetector(
          onTap: onPressed,
          child: ExcludeSemantics(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 13, // Default macOS size
              height: 13,
              decoration: BoxDecoration(
                color: isHovered ? hoverColor : color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: isHovered
                  ? Icon(icon, size: 8, color: Colors.black87)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
