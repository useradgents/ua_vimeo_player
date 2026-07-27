/// Where the large play button is positioned before playback starts.
///
/// Maps to the `play_button_position` player parameter.
enum VimeoPlayButtonPosition {
  /// Let the player decide (the Vimeo default).
  auto,

  /// Anchor the play button to the bottom of the player.
  bottom,

  /// Center the play button within the player.
  center;

  /// The exact string the Vimeo player expects, which is the lowercase name.
  String get wireValue => name;
}
