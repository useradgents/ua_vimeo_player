/// Helpers for converting between [Duration] and the string time formats used
/// by the Vimeo player (the `#t=` URL fragment and raw second values).
abstract final class VimeoTime {
  /// Formats [duration] as the Vimeo start-time hash fragment value, e.g.
  /// `1m2s` for one minute and two seconds.
  ///
  /// The returned string does **not** include the leading `#t=`; callers append
  /// it when composing the URL. Sub-second precision is truncated because the
  /// player only honours whole seconds in the fragment. Negative or zero
  /// durations produce `0s`.
  static String formatHashTime(Duration duration) {
    final totalSeconds = duration.inSeconds;
    if (totalSeconds <= 0) {
      return '0s';
    }
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final buffer = StringBuffer();
    if (minutes > 0) {
      buffer.write('${minutes}m');
    }
    buffer.write('${seconds}s');
    return buffer.toString();
  }

  /// Converts a floating-point number of [seconds] (as reported by the Vimeo JS
  /// SDK) into a [Duration] with millisecond precision.
  static Duration durationFromSeconds(num seconds) {
    if (seconds.isNaN || seconds.isNegative) {
      return Duration.zero;
    }
    return Duration(milliseconds: (seconds * 1000).round());
  }

  /// Converts a [Duration] into a floating-point number of seconds, the format
  /// the Vimeo JS SDK expects for methods such as `setCurrentTime`.
  static double durationToSeconds(Duration duration) {
    return duration.inMilliseconds / 1000.0;
  }
}
