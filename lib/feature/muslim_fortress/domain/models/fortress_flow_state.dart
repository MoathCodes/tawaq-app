import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';

part 'fortress_flow_state.freezed.dart';

/// Mutable session state for the Muslim Fortress screen.
@freezed
abstract class FortressFlowState with _$FortressFlowState {
  /// Creates the flow state.
  const factory FortressFlowState({
    FortressCategory? selectedCategory,
    @Default(false) bool isFocusMode,
    @Default(0) int focusStartIndex,
  }) = _FortressFlowState;
}
