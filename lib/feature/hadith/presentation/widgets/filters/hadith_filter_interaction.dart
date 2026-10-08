import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';

/// Route-owned editing state survives panel/sheet transitions and scrolling.
final hadithFilterInteractionProvider =
    Provider.autoDispose<HadithFilterInteraction>((ref) {
      final state = HadithFilterInteraction();
      ref.onDispose(state.dispose);
      return state;
    });

class HadithFilterInteraction extends ChangeNotifier {
  final scroll = ScrollController();
  final expanded = <int>{};
  final exclude = TextEditingController();
  HadithFilterInteraction() {
    excludeFocus = _focus();
  }
  FocusNode? lastFocused;
  FocusNode _focus() {
    final node = FocusNode();
    node.addListener(() {
      if (node.hasFocus) lastFocused = node;
    });
    return node;
  }

  late final FocusNode excludeFocus;
  final lookupControllers = <HadithLookupKind, TextEditingController>{};
  final lookupChoices = <HadithLookupKind, Map<String, ReferenceChoice>>{};
  TextEditingController lookup(HadithLookupKind kind) =>
      lookupControllers.putIfAbsent(kind, TextEditingController.new);
  Map<String, ReferenceChoice> choices(HadithLookupKind kind) =>
      lookupChoices.putIfAbsent(kind, () => {});
  void replaceLookup(HadithLookupKind kind, TextEditingController next) {
    final old = lookupControllers[kind];
    lookupControllers[kind] = next;
    WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
  }

  final phraseFocus = <TextEditingController, FocusNode>{};
  FocusNode focusFor(TextEditingController field) =>
      phraseFocus.putIfAbsent(field, _focus);
  final phrases = <TextEditingController>[];
  void expand(int index, bool value) {
    value ? expanded.add(index) : expanded.remove(index);
    notifyListeners();
  }

  void sync(HadithFilters filters) {
    if (exclude.text != filters.exclude) exclude.text = filters.exclude;
    while (phrases.length < filters.optionalPhrases.length) {
      phrases.add(TextEditingController());
    }
    while (phrases.length > filters.optionalPhrases.length) {
      final removed = phrases.removeLast();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        removed.dispose();
        phraseFocus.remove(removed)?.dispose();
      });
    }
    for (var i = 0; i < phrases.length; i++) {
      if (phrases[i].text != filters.optionalPhrases[i])
        phrases[i].text = filters.optionalPhrases[i];
    }
  }

  void removePhrase(int index) {
    final removed = phrases.removeAt(index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removed.dispose();
      phraseFocus.remove(removed)?.dispose();
    });
  }

  @override
  void dispose() {
    for (final field in lookupControllers.values) {
      field.dispose();
    }
    scroll.dispose();
    exclude.dispose();
    excludeFocus.dispose();
    for (final node in phraseFocus.values) {
      node.dispose();
    }
    phraseFocus.clear();
    for (final field in phrases) {
      field.dispose();
    }
    super.dispose();
  }
}
