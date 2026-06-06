import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'hadith_search_state.freezed.dart';

/// Runtime search state for hadith result loading.
@freezed
abstract class HadithSearchState with _$HadithSearchState {
  /// Creates the hadith search state.
  const factory HadithSearchState({
    @Default('') String query,
    @Default(1) int page,
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    String? error,
    SearchMetadata? metadata,
    @Default(<DetailedHadith>[]) List<DetailedHadith> results,
    @Default(<String>[]) List<String> favoriteKeys,
  }) = _HadithSearchState;

  const HadithSearchState._();

  /// Whether another page of results is available.
  bool get hasNextPage => metadata?.hasNextPage ?? false;
}
