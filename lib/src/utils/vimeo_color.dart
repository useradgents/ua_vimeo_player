import 'dart:ui';

/// Color conversion helpers shared across the parameter serializers.
abstract final class VimeoColor {
  /// Converts [color] to a 6-digit, lowercase hexadecimal string **without** a
  /// leading `#` and **without** the alpha channel, which is the format the
  /// Vimeo player expects for the `color` and `colors` parameters.
  ///
  /// Alpha is intentionally ignored — the Vimeo player does not support
  /// translucent accent colors.
  static String toHex(Color color) {
    final argb = color.toARGB32();
    final rgb = argb & 0x00FFFFFF;
    return rgb.toRadixString(16).padLeft(6, '0');
  }
}
