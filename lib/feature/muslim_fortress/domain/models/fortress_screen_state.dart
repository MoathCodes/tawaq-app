import 'package:freezed_annotation/freezed_annotation.dart';

part 'fortress_screen_state.freezed.dart';
part 'fortress_screen_state.g.dart';

/// The available tabs in the Muslim Fortress sidebar.
enum FortressSidebarTab {
  /// All chapters tab.
  allChapters,

  /// Favorites tab.
  favorites,
}

/// Persisted UI state for the Muslim Fortress screen.
@freezed
abstract class FortressScreenState with _$FortressScreenState {
  /// Creates the fortress screen state.
  const factory FortressScreenState({
    @Default(FortressSidebarTab.allChapters) FortressSidebarTab sidebarTab,
    @Default([]) List<int> favoriteChapterIds,
    @Default(false) bool defaultBookmarksSeeded,
  }) = _FortressScreenState;

  /// Deserializes the fortress screen state from JSON.
  factory FortressScreenState.fromJson(Map<String, dynamic> json) =>
      _$FortressScreenStateFromJson(json);

  /// Returns the default initial screen state.
  factory FortressScreenState.initial() => const FortressScreenState();
}
