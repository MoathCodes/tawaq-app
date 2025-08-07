import 'dart:io';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/theme/button_style.dart';
import 'package:window_manager/window_manager.dart';

class MacOSWindowControls extends StatelessWidget {
  final VoidCallback? onClose;
  final VoidCallback? onMinimize;
  final VoidCallback? onFullscreen;

  const MacOSWindowControls({
    super.key,
    this.onClose,
    this.onMinimize,
    this.onFullscreen,
  });

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
        _MacOSControlButton(
          color: const Color(0xFF28CA42), // Green
          hoverColor: const Color(0xFF00FF57),
          icon: Icons.fullscreen,
          onPressed: onFullscreen,
        ),
      ],
    );
  }
}

class WindowControls extends StatelessWidget {
  final bool? forceMacStyle;
  const WindowControls({super.key, this.forceMacStyle});

  @override
  Widget build(BuildContext context) {
    final isMaximized = windowManager.isMaximized().asStream();
    final theme = FTheme.of(context);
    final isMacStyle = Platform.isMacOS || forceMacStyle == true;

    if (isMacStyle) {
      return const MacOSWindowControls();
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
          onPress: () async {
            await windowManager.close();
          },
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
                onPress: () async {
                  if (asyncSnapshot.data ?? false) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                },
                child: Icon(
                    asyncSnapshot.data ?? false
                        ? FIcons.maximize2
                        : FIcons.square,
                    size: 14),
              );
            }),

        // Minimize button
        FButton.icon(
          style: (style) => windowControlButtonStyle(
            colors: theme.colors,
            typography: theme.typography,
            style: theme.style,
          ),
          onPress: () async {
            await windowManager.minimize();
          },
          child: const Icon(FIcons.minus, size: 14),
        ),
      ],
    );
  }
}

class _MacOSControlButton extends StatefulWidget {
  final Color color;
  final Color hoverColor;
  final IconData icon;
  final VoidCallback? onPressed;

  const _MacOSControlButton({
    required this.color,
    required this.hoverColor,
    required this.icon,
    this.onPressed,
  });

  @override
  State<_MacOSControlButton> createState() => _MacOSControlButtonState();
}

class _MacOSControlButtonState extends State<_MacOSControlButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 13, // Default macOS size
          height: 13,
          decoration: BoxDecoration(
            color: _isHovered ? widget.hoverColor : widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          child: _isHovered
              ? Icon(
                  widget.icon,
                  size: 8,
                  color: Colors.black87,
                )
              : null,
        ),
      ),
    );
  }
}
