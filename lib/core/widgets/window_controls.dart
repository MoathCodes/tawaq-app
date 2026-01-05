import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/hooks/hooks.dart';
import 'package:hasanat/theme/button_style.dart';
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
  final void Function(AsyncSnapshot<bool> snapshot) onFullscreen;

  /// A stream that emits whether the window is maximized.
  final Stream<bool> isMaximized;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        _MacOSControlButton(
          color: const Color(0xFFFF5F57), // Red
          hoverColor: const Color(0xFFFF4A40),
          icon: Icons.close,
          onPressed: onClose,
        ),
        _MacOSControlButton(
          color: const Color(0xFFFFBD2E), // Yellow
          hoverColor: const Color(0xFFFFAA00),
          icon: Icons.minimize,
          onPressed: onMinimize,
        ),
        StreamBuilder(
          stream: isMaximized,
          builder: (context, snapshot) => _MacOSControlButton(
            color: const Color(0xFF28CA42), // Green
            hoverColor: const Color(0xFF00FF57),
            icon: Icons.fullscreen,
            onPressed: () => onFullscreen(snapshot),
          ),
        ),
      ],
    );
  }
}

/// Window controls that adapt to the current platform.
class WindowControls extends StatelessWidget {
  /// Creates a new instance of [WindowControls].
  const WindowControls({super.key, this.forceMacStyle});

  /// Whether to force the macOS style.
  final bool? forceMacStyle;

  @override
  Widget build(BuildContext context) {
    final isMaximized = windowManager.isMaximized().asStream();
    final theme = FTheme.of(context);
    final isMacStyle = Platform.isMacOS || (forceMacStyle ?? false);

    if (isMacStyle) {
      return MacOSWindowControls(
        onClose: _closeWindow,
        onMinimize: _minimizeWindow,
        isMaximized: isMaximized,
        onFullscreen: _maximizeWindow,
      );
    }

    return Row(
      spacing: 6,
      children: [
        // Close button (red hover effect)
        FButton.icon(
          style: (style) => closeButtonStyle(
            colors: theme.colors,
            typography: theme.typography,
            style: theme.style,
          ),
          onPress: _closeWindow,
          child: const Icon(FIcons.x, size: 14),
        ),

        // Maximize button
        StreamBuilder(
          stream: isMaximized,
          builder: (context, asyncSnapshot) {
            return FButton.icon(
              style: (style) => windowControlButtonStyle(
                colors: theme.colors,
                typography: theme.typography,
                style: theme.style,
              ),
              onPress: () => _maximizeWindow(asyncSnapshot),
              child: Icon(
                asyncSnapshot.data ?? false ? FIcons.maximize2 : FIcons.square,
                size: 14,
              ),
            );
          },
        ),

        // Minimize button
        FButton.icon(
          style: (style) => windowControlButtonStyle(
            colors: theme.colors,
            typography: theme.typography,
            style: theme.style,
          ),
          onPress: _minimizeWindow,
          child: const Icon(FIcons.minus, size: 14),
        ),
      ],
    );
  }

  Future<void> _closeWindow() async {
    await windowManager.close();
  }

  Future<void> _maximizeWindow(AsyncSnapshot<bool> asyncSnapshot) async {
    if (asyncSnapshot.data ?? false) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  Future<void> _minimizeWindow() async {
    await windowManager.minimize();
  }
}

class _MacOSControlButton extends HookWidget {
  const _MacOSControlButton({
    required this.color,
    required this.hoverColor,
    required this.icon,
    this.onPressed,
  });
  final Color color;
  final Color hoverColor;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final (:isHovered, :setHovered) = useHoverState();

    return MouseRegion(
      onEnter: (_) => setHovered(true),
      onExit: (_) => setHovered(false),
      child: GestureDetector(
        onTap: onPressed,
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
          child: isHovered ? Icon(icon, size: 8, color: Colors.black87) : null,
        ),
      ),
    );
  }
}
