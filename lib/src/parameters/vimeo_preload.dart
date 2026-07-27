/// Controls how aggressively the Vimeo player preloads video data.
///
/// Maps to the `preload` player parameter.
enum VimeoPreload {
  /// Preload only the video metadata.
  metadata('metadata'),

  /// Preload metadata when the user hovers over the player (the Vimeo default).
  metadataOnHover('metadata_on_hover'),

  /// Preload the metadata and begin buffering the video.
  auto('auto'),

  /// Begin buffering the video when the user hovers over the player.
  autoOnHover('auto_on_hover'),

  /// Do not preload anything.
  none('none');

  const VimeoPreload(this.wireValue);

  /// The exact string the Vimeo player expects for this preload strategy.
  final String wireValue;
}
