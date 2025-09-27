import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/widgets/animated_icon_button.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';

class ThemeModeButton extends ConsumerWidget {
  const ThemeModeButton({
    super.key,
  });


  @override
  Widget build(BuildContext context, WidgetRef ref) {
        final themeMode = ref.watch(themeNotifierProvider);
    return AnimatedIconButton(
      primaryIcon: FIcons.sun,
      secondaryIcon: FIcons.moon,
      animationDuration: const Duration(milliseconds: 300),
      buttonStyle: FButtonStyle.ghost(),
      isSecondaryActive: themeMode.value?.themeMode == ThemeMode.dark,
      onPressed: () {
        ref.read(themeNotifierProvider.notifier).toggleThemeMode();
      },
    );
  }
}