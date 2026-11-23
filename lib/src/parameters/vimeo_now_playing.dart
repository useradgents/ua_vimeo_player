import 'package:flutter/foundation.dart';

/// What the system media controls (iOS lock screen, Control Center) show for
/// the video, in place of the name and owner set on Vimeo.
///
/// The Vimeo player fills those controls itself, from the video's name on
/// Vimeo (often the uploaded file name) and its owner's name. Each non-null
/// field here replaces the matching one; the artwork stays Vimeo's thumbnail.
@immutable
class VimeoNowPlaying {
  /// Creates now-playing metadata.
  const VimeoNowPlaying({this.title, this.artist});

  /// The main line, e.g. the title of the content the video belongs to.
  final String? title;

  /// The line below the title, e.g. the app or publisher name.
  final String? artist;

  /// The JSON shape sent to the player's web view.
  Map<String, Object?> toJson() => {'title': title, 'artist': artist};

  @override
  bool operator ==(Object other) =>
      other is VimeoNowPlaying &&
      other.title == title &&
      other.artist == artist;

  @override
  int get hashCode => Object.hash(title, artist);
}
