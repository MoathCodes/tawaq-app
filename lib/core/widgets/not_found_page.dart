import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class NotFoundPage extends StatelessWidget {
  final String errorMsg;
  const NotFoundPage({super.key, required this.errorMsg});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
                  "This Page Doesn't Exists. Please go back to the Home Page")
              .h1(),
          Text(errorMsg).small().muted(),
          gap(12),
          SecondaryButton(
            leading: const Icon(BootstrapIcons.arrowLeft),
            child: const Text("Prayer Page"),
            onPressed: () {
              context.go('/prayer');
            },
          )
        ],
      ),
    ));
  }
}
