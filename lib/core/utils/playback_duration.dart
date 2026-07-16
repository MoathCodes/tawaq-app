/// Formats playback position/duration for compact media controls.
///
/// Under one hour: `m:ss` (e.g. `7:41`).
/// At or above one hour: `h:mm:ss` (e.g. `1:59:41` instead of `119:41`).
String formatPlaybackDuration(Duration duration) {
  final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds ~/ 60) % 60;
  final seconds = totalSeconds % 60;
  final secondsLabel = seconds.toString().padLeft(2, '0');

  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$secondsLabel';
  }
  return '$minutes:$secondsLabel';
}
