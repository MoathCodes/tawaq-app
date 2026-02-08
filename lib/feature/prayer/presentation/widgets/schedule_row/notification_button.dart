import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:forui/forui.dart';

/// Notification bell button for prayer reminders.
class NotificationButton extends StatelessWidget {
  /// Creates a [NotificationButton].
  const NotificationButton({required this.colors, super.key});

  /// Theme colors for styling.
  final FColors colors;

  @override
  Widget build(BuildContext context) {
    return HookBuilder(
      builder: (context) {
        final isEnabled = useState(true);
        return FButton.icon(
          style: isEnabled.value
              ? FButtonStyle.primary()
              : FButtonStyle.secondary(),
          onPress: () {
            isEnabled.value = !isEnabled.value;
          },
          child: Icon(
            isEnabled.value ? FIcons.bell : FIcons.bellOff,
            size: 20.sp,
          ),
        );
      },
    );
  }
}
