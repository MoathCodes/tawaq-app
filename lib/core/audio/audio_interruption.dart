import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Coordinates exclusive audio interruptions without depending on a feature.
///
/// The app composition supplies the recitation hooks, while feature-level
/// preview providers register a settle callback. Alert composition can then
/// settle an active preview before capturing the shared service volume.
class AudioInterruptionCoordinator {
  Future<void> Function()? _suspendRecitation;
  Future<void> Function()? _resumeRecitation;
  Future<void> Function()? _settlePreview;

  /// Registers the app-owned recitation interruption hooks.
  AudioInterruptionRegistration registerRecitation({
    required Future<void> Function() suspend,
    required Future<void> Function() resume,
  }) {
    final previousSuspend = _suspendRecitation;
    final previousResume = _resumeRecitation;
    _suspendRecitation = suspend;
    _resumeRecitation = resume;
    return AudioInterruptionRegistration(() {
      if (identical(_suspendRecitation, suspend)) {
        _suspendRecitation = previousSuspend;
      }
      if (identical(_resumeRecitation, resume)) {
        _resumeRecitation = previousResume;
      }
    });
  }

  /// Registers the one active preview slot.
  AudioInterruptionRegistration registerPreview(
    Future<void> Function() settle,
  ) {
    final previous = _settlePreview;
    _settlePreview = settle;
    return AudioInterruptionRegistration(() {
      if (identical(_settlePreview, settle)) _settlePreview = previous;
    });
  }

  /// Suspends the currently composed recitation, if one is registered.
  Future<void> suspendRecitation() =>
      _suspendRecitation?.call() ?? Future<void>.value();

  /// Resumes the currently composed recitation, if one is registered.
  Future<void> resumeRecitation() =>
      _resumeRecitation?.call() ?? Future<void>.value();

  /// Settles the active preview before another audio owner captures volume.
  Future<void> settlePreview() =>
      _settlePreview?.call() ?? Future<void>.value();
}

/// Idempotent registration that removes itself once.
class AudioInterruptionRegistration(this._remove) {
  final void Function() _remove;
  bool _removed = false;

  /// Removes the registration once.
  void dispose() {
    if (_removed) return;
    _removed = true;
    _remove();
  }
}

/// Process-wide audio interruption coordinator.
final audioInterruptionCoordinatorProvider =
    Provider<AudioInterruptionCoordinator>((ref) {
      return AudioInterruptionCoordinator();
    });
