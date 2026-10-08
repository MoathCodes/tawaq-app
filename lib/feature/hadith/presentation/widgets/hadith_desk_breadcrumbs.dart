import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_session_state.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';

class HadithDeskBreadcrumbs extends ConsumerWidget {
  const HadithDeskBreadcrumbs({this.reader = false, super.key});
  final bool reader;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      hadithSessionControllerProvider.select(
        (s) =>
            (s.context, s.topicPath, s.readerTrail.length, s.reader?.selection),
      ),
    );
    final session = ref.read(hadithSessionControllerProvider);
    final controller = ref.read(hadithSessionControllerProvider.notifier);
    final category = session.context is CategoryCollection
        ? (session.context as CategoryCollection).category
        : null;
    if (!reader && category == null && session.topicPath.isEmpty)
      return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: FBreadcrumb(
        children: [
          if (!reader || session.topicPath.isNotEmpty || category != null) ...[
            FBreadcrumbItem(
              onPress: () => controller.navigateTopics(const []),
              child: Text(context.l10n.hadithTopics),
            ),
            for (final (index, step) in session.topicPath.indexed)
              FBreadcrumbItem(
                current:
                    !reader &&
                    category == null &&
                    index == session.topicPath.length - 1,
                onPress: () => controller.navigateTopics(
                  session.topicPath.take(index + 1).toList(),
                ),
                child: Text(step.label),
              ),
            if (category != null)
              FBreadcrumbItem(
                current: !reader,
                onPress: controller.clearSelection,
                child: Text(category.name),
              ),
          ],
          if (reader)
            for (final (index, entry) in session.readerTrail.indexed)
              FBreadcrumbItem(
                current: index == session.readerTrail.length - 1,
                onPress: () => controller.returnToReader(index),
                child: Text(
                  entry.selection is ProseSelection
                      ? context.l10n.hadithSharh
                      : context.l10n.hadithTargetRecords,
                ),
              ),
        ],
      ),
    );
  }
}
