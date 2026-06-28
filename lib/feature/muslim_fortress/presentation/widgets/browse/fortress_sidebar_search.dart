import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/muslim_fortress_provider.dart';

/// Sidebar search field state backed by [muslimFortressSearchQueryProvider].
typedef FortressSearchFieldState = ({
  TextEditingController controller,
  FocusNode focusNode,
  String query,
});

/// Owns the sidebar search controller and syncs with the global query provider.
FortressSearchFieldState useFortressSearchField(WidgetRef ref) {
  final committedQuery = ref.watch(muslimFortressSearchQueryProvider);
  final controller = useTextEditingController(text: committedQuery);
  useListenable(controller);
  final focusNode = useFocusNode();

  final focusSearch = useCallback(
    focusNode.requestFocus,
    [focusNode],
  );
  useRegisterAppSearchFocus(focusSearch);

  useEffect(() {
    if (controller.text != committedQuery) {
      controller.text = committedQuery;
    }
    return null;
  }, [committedQuery]);

  final debouncedCommit = useDebouncedCallback(
    () => ref
        .read(muslimFortressSearchQueryProvider.notifier)
        .setQuery(controller.text),
    duration: const Duration(milliseconds: 300),
  );

  useEffect(() {
    debouncedCommit();
    return null;
  }, [controller.text]);

  return (
    controller: controller,
    focusNode: focusNode,
    query: controller.text,
  );
}
