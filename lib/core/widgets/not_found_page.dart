import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

class NotFoundPage extends StatelessWidget {
  final String errorMsg;
  const NotFoundPage({super.key, required this.errorMsg});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
        child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
              "This Page Doesn't Exists. Please go back to the Home Page"),
          Text(errorMsg),
          // gap(12),
          FButton(
            style: FButtonStyle.secondary(),
            // leading: const Icon(BootstrapIcons.arrowLeft),
            child: const Text("Prayer Page"),
            onPress: () {
              context.go('/prayer');
            },
          )
        ],
      ),
    ));
  }
}
