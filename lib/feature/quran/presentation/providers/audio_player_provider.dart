import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_player_provider.freezed.dart';

/// State for the global Quran audio player.
@freezed
abstract class AudioPlayerState with _$AudioPlayerState {
  /// Creates an audio player state.
  const factory AudioPlayerState({
    /// Whether audio is currently playing.
    @Default(false) bool isPlaying,

    /// Whether the player is visible/active.
    @Default(false) bool isActive,

    /// Whether repeat mode is enabled.
    @Default(false) bool isRepeatEnabled,

    /// The current surah name.
    @Default('Al-Fatihah') String surahName,

    /// The current ayah number.
    @Default(1) int currentAyahNumber,

    /// The current page number.
    @Default(1) int currentPage,

    /// List of ayah IDs on the current page.
    @Default([]) List<int> ayahIds,

    /// The currently selected ayah index in the list.
    @Default(0) int currentAyahIndex,

    /// The reciter name.
    @Default('Mishary') String reciterName,

    /// The currently selected ayah ID.
    int? selectedAyahId,
  }) = _AudioPlayerState;
}

/// Provider for the global audio player state.
final audioPlayerProvider =
    NotifierProvider<AudioPlayerNotifier, AudioPlayerState>(
      AudioPlayerNotifier.new,
    );

/// Notifier for managing audio player state.
class AudioPlayerNotifier extends Notifier<AudioPlayerState> {
  @override
  AudioPlayerState build() => const AudioPlayerState();

  /// Shows the audio player with the given page info.
  void showPlayer({
    required String surahName,
    required int currentAyahNumber,
    required int currentPage,
    required List<int> ayahIds,
  }) {
    state = state.copyWith(
      isActive: true,
      surahName: surahName,
      currentAyahNumber: currentAyahNumber,
      currentPage: currentPage,
      ayahIds: ayahIds,
      currentAyahIndex: 0,
    );
  }

  /// Hides the audio player.
  void hidePlayer() {
    state = state.copyWith(isActive: false, isPlaying: false);
  }

  /// Toggles play/pause.
  void togglePlayPause() {
    state = state.copyWith(isPlaying: !state.isPlaying);
  }

  /// Sets playing state.
  void setPlaying({required bool isPlaying}) {
    state = state.copyWith(isPlaying: isPlaying);
  }

  /// Toggles repeat mode.
  void toggleRepeat() {
    state = state.copyWith(isRepeatEnabled: !state.isRepeatEnabled);
  }

  /// Selects an ayah by index.
  void selectAyahByIndex(int index) {
    if (index >= 0 && index < state.ayahIds.length) {
      state = state.copyWith(
        currentAyahIndex: index,
        currentAyahNumber: index + 1, // Simplified; in real app, get from ayah
      );
    }
  }

  /// Selects an ayah by ID and ayah number.
  void selectAyahById(int ayahId, {int? ayahNumber}) {
    state = state.copyWith(
      selectedAyahId: ayahId,
      currentAyahNumber: ayahNumber ?? state.currentAyahNumber,
    );
    final index = state.ayahIds.indexOf(ayahId);
    if (index >= 0) {
      selectAyahByIndex(index);
    }
  }

  /// Goes to the previous ayah.
  void previousAyah() {
    if (state.currentAyahIndex > 0) {
      selectAyahByIndex(state.currentAyahIndex - 1);
    }
  }

  /// Goes to the next ayah.
  void nextAyah() {
    if (state.currentAyahIndex < state.ayahIds.length - 1) {
      selectAyahByIndex(state.currentAyahIndex + 1);
    }
  }

  /// Updates page info when navigating.
  void updatePageInfo({
    required String surahName,
    required int currentPage,
    required List<int> ayahIds,
  }) {
    state = state.copyWith(
      surahName: surahName,
      currentPage: currentPage,
      ayahIds: ayahIds,
      currentAyahIndex: 0,
      currentAyahNumber: 1,
    );
  }
}
