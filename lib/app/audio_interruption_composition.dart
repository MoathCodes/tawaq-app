import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tawaq/core/audio/audio_interruption.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';

/// Composes the feature-owned recitation lifecycle into core audio
/// interruption coordination at the app boundary.
final audioInterruptionCompositionProvider = Provider<void>((ref) {
  final coordinator = ref.read(audioInterruptionCoordinatorProvider);
  final registration = coordinator.registerRecitation(
    suspend: () =>
        ref.read(recitationControllerProvider.notifier).suspendForAlert(),
    resume: () =>
        ref.read(recitationControllerProvider.notifier).resumeAfterAlert(),
  );
  ref.onDispose(registration.dispose);
});
