import 'dart:ui';

import '../utils/vimeo_color.dart';

/// A one-to-four color palette for the Vimeo player, serialized to the `colors`
/// parameter as comma-separated 6-digit hex values.
///
/// The colors are applied, in order, to: the player background ([primary]), the
/// accent/controls color ([accent]), the icon and text color ([iconText]), and
/// the overall background ([background]). Trailing unset colors are dropped from
/// the wire representation so `colors=000000,00adef` is valid.
///
/// See Vimeo's *About Player Parameters* documentation for how each slot is
/// interpreted.
class VimeoColorPalette {
  /// Creates a palette. Only [primary] is required; the remaining colors are
  /// optional and dropped from the serialized value when `null`.
  const VimeoColorPalette({
    required this.primary,
    this.accent,
    this.iconText,
    this.background,
  });

  /// Color 1 — typically the player background. Vimeo default `#000000`.
  final Color primary;

  /// Color 2 — the accent color used for controls. Vimeo default `#00adef`.
  final Color? accent;

  /// Color 3 — the icon and text color. Vimeo default `#ffffff`.
  final Color? iconText;

  /// Color 4 — the overall background color. Vimeo default `#000000`.
  final Color? background;

  /// Serializes the palette to the comma-joined 6-hex form expected by the
  /// `colors` parameter, dropping trailing `null` colors.
  String toWire() {
    final parts = <String>[VimeoColor.toHex(primary)];
    // Colors must keep their positional order, so a null in the middle is
    // preserved as an empty slot while trailing nulls are dropped.
    final tail = <String?>[
      accent == null ? null : VimeoColor.toHex(accent!),
      iconText == null ? null : VimeoColor.toHex(iconText!),
      background == null ? null : VimeoColor.toHex(background!),
    ];
    var lastNonNull = -1;
    for (var i = 0; i < tail.length; i++) {
      if (tail[i] != null) {
        lastNonNull = i;
      }
    }
    for (var i = 0; i <= lastNonNull; i++) {
      parts.add(tail[i] ?? '');
    }
    return parts.join(',');
  }

  /// Returns a copy of this palette with the given fields replaced.
  VimeoColorPalette copyWith({
    Color? primary,
    Color? accent,
    Color? iconText,
    Color? background,
  }) {
    return VimeoColorPalette(
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
      iconText: iconText ?? this.iconText,
      background: background ?? this.background,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is VimeoColorPalette &&
        other.primary == primary &&
        other.accent == accent &&
        other.iconText == iconText &&
        other.background == background;
  }

  @override
  int get hashCode => Object.hash(primary, accent, iconText, background);

  @override
  String toString() => 'VimeoColorPalette(${toWire()})';
}
