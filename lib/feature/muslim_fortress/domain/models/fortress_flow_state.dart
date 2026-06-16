import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';

/// Mutable session state for the Muslim Fortress screen.
class FortressFlowState {
  /// Creates the flow state.
  const FortressFlowState({
    this.selectedCategory,
    this.isFocusMode = false,
    this.focusStartIndex = 0,
  });

  /// The chapter currently shown in the main pane.
  final FortressCategory? selectedCategory;

  /// Whether focus-reading mode is active.
  final bool isFocusMode;

  /// Initial dua index when entering focus-reading mode.
  final int focusStartIndex;

  /// Returns a copy with updated flow state values.
  FortressFlowState copyWith({
    FortressCategory? selectedCategory,
    bool? isFocusMode,
    int? focusStartIndex,
    bool clearSelectedCategory = false,
  }) {
    return FortressFlowState(
      selectedCategory: clearSelectedCategory
          ? null
          : selectedCategory ?? this.selectedCategory,
      isFocusMode: isFocusMode ?? this.isFocusMode,
      focusStartIndex: focusStartIndex ?? this.focusStartIndex,
    );
  }
}
