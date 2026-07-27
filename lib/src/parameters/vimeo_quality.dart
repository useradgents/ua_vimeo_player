/// The set of playback qualities exposed by the Vimeo player.
///
/// Use [wireValue] when sending a quality to the player and [fromWire] when
/// parsing a `qualitychange` event or a `getQuality()` result.
enum VimeoQuality {
  /// Let the player choose the best quality for the current conditions.
  auto('auto'),

  /// 240p.
  q240p('240p'),

  /// 360p.
  q360p('360p'),

  /// 540p.
  q540p('540p'),

  /// 720p (HD).
  q720p('720p'),

  /// 1080p (Full HD).
  q1080p('1080p'),

  /// 2K (1440p).
  q2k('2k'),

  /// 4K (2160p).
  q4k('4k');

  const VimeoQuality(this.wireValue);

  /// The exact string the Vimeo player uses for this quality.
  final String wireValue;

  /// Parses a quality [value] coming from the Vimeo player.
  ///
  /// Unknown values (including `null`) fall back to [VimeoQuality.auto], since
  /// the player occasionally reports transient or undocumented values.
  static VimeoQuality fromWire(String? value) {
    if (value == null) {
      return VimeoQuality.auto;
    }
    for (final quality in VimeoQuality.values) {
      if (quality.wireValue == value) {
        return quality;
      }
    }
    return VimeoQuality.auto;
  }
}
