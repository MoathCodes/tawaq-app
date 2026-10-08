import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_session_state.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_detail_pane.dart';
import 'package:tawaq/theme/theme.dart';

/// Source-backed topic entry points. The complete catalogue is searchable.
class HadithTopics extends HookConsumerWidget {
  const HadithTopics({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(
      hadithSessionControllerProvider.select((s) => s.topicPath),
    );
    final query = useTextEditingController();
    final submitted = useState('');
    useEffect(() {
      query.clear();
      submitted.value = '';
      return null;
    }, [path]);
    final controller = ref.read(hadithSessionControllerProvider.notifier);
    Widget category(ThematicCategory item) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: FButton(
              variant: .ghost,
              onPress: () => controller.openCategory(item),
              child: Flexible(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(item.name),
                ),
              ),
            ),
          ),
          FButton.icon(
            variant: .ghost,
            semanticsTooltip: context.l10n.hadithTopics,
            onPress: () => controller.navigateTopics([
              ...path,
              HadithTopicStep(CategorySelector(item.id), item.name),
            ]),
            child: const Icon(FLucideIcons.chevronDown, size: 16),
          ),
        ],
      ),
    );
    Widget categories(List<ThematicCategory> items) => LayoutBuilder(
      builder: (_, constraints) {
        final columns = constraints.maxWidth >= 600 ? 2 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
        return Wrap(
          spacing: 16,
          children: [
            for (final item in items)
              SizedBox(width: width, child: category(item)),
          ],
        );
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        Text(
          context.l10n.hadithTopics,
          style: context.theme.typography.body.lg.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        FTextField(
          control: .managed(controller: query),
          hint: context.l10n.hadithTopicSearch,
          onSubmit: (value) {
            if (value.trim().length <= 500) submitted.value = value.trim();
          },
          suffixBuilder: (_, _, _) => FButton.icon(
            variant: .ghost,
            semanticsTooltip: context.l10n.hadithSearchAction,
            onPress: () {
              if (query.text.trim().length <= 500)
                submitted.value = query.text.trim();
            },
            child: const Icon(FLucideIcons.search, size: 16),
          ),
        ),
        if (submitted.value.isNotEmpty)
          HadithAsyncDetailsSection<ApiResponse<List<ThematicCategory>>>(
            value: ref.watch(hadithTopicSearchProvider(submitted.value)),
            onRetry: () {
              controller.retryInitialization();
              ref.invalidate(hadithTopicSearchProvider(submitted.value));
            },
            dataBuilder: (response) => response.data.isEmpty
                ? const HadithSectionPlaceholder()
                : categories(response.data),
          )
        else if (path.isNotEmpty)
          HadithAsyncDetailsSection<ApiResponse<List<ThematicCategory>>>(
            value: ref.watch(hadithTopicChildrenProvider(path.last.selector)),
            onRetry: () {
              controller.retryInitialization();
              ref.invalidate(hadithTopicChildrenProvider(path.last.selector));
            },
            dataBuilder: (response) => response.data.isEmpty
                ? const HadithSectionPlaceholder()
                : categories(response.data),
          )
        else
          HadithAsyncDetailsSection<ApiResponse<List<ThematicRoot>>>(
            value: ref.watch(hadithTopicRootsProvider),
            onRetry: () {
              controller.retryInitialization();
              ref.invalidate(hadithTopicRootsProvider);
            },
            dataBuilder: (response) {
              // Prefer familiar entry points when present; keep labels and selectors
              // exactly as supplied by Dorar. Never manufacture a category.
              const preferred = [
                'صلاة',
                'إيمان',
                'علم',
                'ذكر',
                'صيام',
                'زكاة',
                'أخلاق',
                'دعاء',
              ];
              final roots = <ThematicRoot>[];
              for (final word in preferred) {
                final matches =
                    response.data
                        .where(
                          (r) => r.name.contains(word) && !roots.contains(r),
                        )
                        .toList()
                      ..sort((a, b) => a.name.length.compareTo(b.name.length));
                if (matches.isNotEmpty) roots.add(matches.first);
              }
              for (final root in response.data) {
                if (roots.length >= 8) break;
                if (!roots.contains(root)) roots.add(root);
              }
              return roots.isEmpty
                  ? const HadithSectionPlaceholder()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 540
                            ? 3
                            : constraints.maxWidth >= 320
                            ? 2
                            : 1;
                        final width =
                            (constraints.maxWidth - (columns - 1) * 10) /
                            columns;
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final root in roots.take(8))
                              SizedBox(
                                width: width,
                                child: FButton(
                                  variant: .outline,
                                  onPress: () => controller.navigateTopics([
                                    HadithTopicStep(root.selector, root.name),
                                  ]),
                                  child: Flexible(
                                    child: Row(
                                      children: [
                                        Icon(
                                          FLucideIcons.bookOpen,
                                          size: 18,
                                          color: context.theme.colors.primary,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(child: Text(root.name)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    );
            },
          ),
      ],
    );
  }
}
